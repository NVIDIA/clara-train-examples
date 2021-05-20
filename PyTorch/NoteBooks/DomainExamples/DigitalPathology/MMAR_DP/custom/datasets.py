import math
import os

import numpy as np
from monai.data import Dataset, SmartCacheDataset
from skimage.transform import resize

from image_reader import WSIReader


class PatchWSIDataset(Dataset):
    """
    Load whole slide images and associated class labels and create patches
    """

    def __init__(self, data, region_size, grid_size, patch_size, image_reader_name="CuImage", transform=None):
        if type(region_size) == int:
            self.region_size = (region_size, region_size)
        else:
            self.region_size = region_size
        if type(grid_size) == int:
            self.grid_size = (grid_size, grid_size)
        else:
            self.grid_size = grid_size
        self.sub_region_size = (self.region_size[0] / self.grid_size[0], self.region_size[1] / self.grid_size[1])
        self.patch_size = patch_size

        self.transform = transform
        self.image_base_path = data[0]["image"]
        self.samples = self.load_samples(data[0]["label"])
        self.image_path_list = {x[0] for x in self.samples}
        self.num_samples = len(self.samples)

        self.image_reader_name = image_reader_name
        self.image_reader = WSIReader(image_reader_name)
        self.cu_image_dict = {}
        self._fetch_cu_images()

    def _fetch_cu_images(self):
        for image_path in self.image_path_list:
            self.cu_image_dict[image_path] = self.image_reader.read(image_path)

    def process_label_row(self, row):
        row = row.strip("\n").split(",")
        # create full image path
        image_name = row[0] + ".tif"
        image_path = os.path.join(self.image_base_path, image_name)
        # change center locations to upper left location
        location = (int(row[1]) - self.region_size[0] // 2, int(row[2]) - self.region_size[1] // 2)
        # convert labels to float32 and add empty HxW channel to label
        labels = tuple(int(lbl) for lbl in row[3:])
        labels = np.array(labels, dtype=np.float32)[:, np.newaxis, np.newaxis]
        return image_path, location, labels

    def load_samples(self, loc_path):
        with open(loc_path) as label_file:
            rows = [self.process_label_row(row) for row in label_file.readlines()]
        return rows

    def __len__(self):
        return self.num_samples

    def __getitem__(self, index):
        image_path, location, labels = self.samples[index]
        if self.image_reader_name == 'openslide':
            img_obj = self.image_reader.read(image_path)
        else:
            img_obj = self.cu_image_dict[image_path]
        images = self.image_reader.get_data(
            img_obj=img_obj,
            location=location,
            size=self.region_size,
            grid_shape=self.grid_size,
            patch_size=self.patch_size,
        )
        samples = [{"image": images[i], "label": labels[i]} for i in range(labels.shape[0])]
        if self.transform:
            samples = self.transform(samples)
        return samples


class SmartCachePatchWSIDataset(SmartCacheDataset):
    """
    Add SmartCache functionality to PatchWSIDataset
    """

    def __init__(
        self,
        data,
        region_size,
        grid_size,
        patch_size,
        transform,
        replace_rate,
        cache_num,
        cache_rate=1.0,
        num_init_workers=None,
        num_replace_workers=0,
        image_reader_name="CuImage",
    ):
        extractor = PatchWSIDataset(data, region_size, grid_size, patch_size, image_reader_name)
        super().__init__(
            data=extractor,
            transform=transform,
            replace_rate=replace_rate,
            cache_num=cache_num,
            cache_rate=cache_rate,
            num_init_workers=num_init_workers,
            num_replace_workers=num_replace_workers,
        )


class SlidingWindowWSIDataset(Dataset):
    """
    Load image patches in a sliding window manner with foreground mask
    Parameters include image and mask paths, and patch_size
    Output will be at same level as the foreground mask
    """

    def __init__(self, data, patch_size, image_reader_name="CuImage", transform=None):
        if type(patch_size) == int:
            self.patch_size = (patch_size, patch_size)
        else:
            self.patch_size = patch_size

        self.image_reader = WSIReader(image_reader_name)
        self.down_ratio = int(np.ceil(self.patch_size[0] / 32) - 6)
        self.transform = transform
        self.coords = []
        self.info = {}

        for wsi_sample in data:
            image_name, img, num_idx, x_idx, y_idx, level, ratio, mask_dims, image_dims = self._preprocess(wsi_sample)
            self.info[image_name] = {
                "img": img,
                "mask_dims": mask_dims,
                "image_dims": image_dims,
                "num_idx": num_idx,
                "level": level,
                "ratio": ratio,
                "counter": 0,
            }
            coords = zip([image_name] * num_idx, x_idx, y_idx)
            self.coords.extend(coords)

        self.total_n_patches = len(self.coords)

    def _preprocess(self, sample):
        image_path = sample["image"]
        mask_path = sample["label"]
        image_name = os.path.splitext(os.path.basename(image_path))[0]

        img = self.image_reader.read(image_path)
        msk = np.load(mask_path)

        dim_y_img, dim_x_img, _ = img.shape
        dim_x_msk, dim_y_msk = msk.shape

        ratio_x = dim_x_img / dim_x_msk
        ratio_y = dim_y_img / dim_y_msk
        level_x = math.log2(ratio_x)

        if ratio_x != ratio_y:
            raise Exception(
                "{}: Image/Mask dimension does not match ,"
                " dim_x_img / dim_x_msk : {} / {},"
                " dim_y_img / dim_y_msk : {} / {}".format(image_name, dim_x_img, dim_x_msk, dim_y_img, dim_y_msk)
            )
        else:
            if not level_x.is_integer():
                raise Exception(
                    "{}: Mask not at regular level (ratio not power of 2),"
                    " image / mask ratio: {},".format(image_name, ratio_x)
                )
            else:
                ratio = ratio_x
                level = level_x
                print("{}: Mask at level {}, with ratio {}".format(image_name, int(level), int(ratio)))

        print("Downsample ratio {}".format(self.down_ratio))

        msk_down = resize(msk, (int(dim_x_msk / self.down_ratio), int(dim_y_msk / self.down_ratio)))

        # get all indices for tissue region from the foreground mask
        x_idx, y_idx = np.where(msk_down)
        # output same size as the foreground mask
        # attention: not original wsi image size
        self.x_idx = x_idx * self.down_ratio
        self.y_idx = y_idx * self.down_ratio
        num_idx = len(x_idx)

        return image_name, img, num_idx, x_idx, y_idx, level, ratio, (dim_x_msk, dim_y_msk), (dim_x_img, dim_y_img)

    def _load_sample(self, index):
        """
        Load patch for sliding window inference on WSI
        Read ROI with patch_size at patch_loc into a dictionary of {'image': array, "name": str}.
        """
        name, x_msk, y_msk = self.coords[index]
        ratio = self.info[name]["ratio"]

        # convert to image space
        x_img = int((x_msk + 0.5) * ratio - self.patch_size[0] / 2)
        y_img = int((y_msk + 0.5) * ratio - self.patch_size[1] / 2)
        location = (x_img, y_img)

        image = self.image_reader.get_data(img_obj=self.info[name]["img"], location=location, size=self.patch_size)

        sample = {"image": image, "name": name, "location": (x_msk, y_msk), "ratio": ratio}
        return sample

    def __len__(self):
        return self.total_n_patches

    def __getitem__(self, index):
        sample = self._load_sample(index)
        if self.transform:
            sample = self.transform(sample)
        return sample
