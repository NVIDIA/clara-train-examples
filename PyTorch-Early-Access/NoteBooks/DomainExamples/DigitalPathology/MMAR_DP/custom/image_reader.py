from typing import List, Optional, Sequence, Tuple, Type, Union

import numpy as np
from monai.data.image_reader import ImageReader
from monai.data.utils import is_supported_format
from monai.utils import ensure_tuple, optional_import

cuimage, has_cci = optional_import("cuimage")
openslide, has_osl = optional_import("openslide")

class WSIReader(ImageReader):
    """
    Read whole slide imaging

    """

    def __init__(self, wsi_reader_name: str = "CuImage"):
        super().__init__()
        self.wsi_reader_name = wsi_reader_name.lower()
        if self.wsi_reader_name == "cuclaraimage":
            self.wsi_reader = cuimage.CuImage
            print('> CuClaraImage is being used.')
        elif self.wsi_reader_name == "openslide":
            self.wsi_reader = openslide.OpenSlide
            print('> OpenSlide is being used    .')
        else:
            raise ValueError('`wsi_reader_name` should be either "CuClaraImage" or "OpenSlide"')

    def verify_suffix(self, filename: Union[Sequence[str], str]) -> bool:
        """
        Verify whether the specified file or files format is supported by WSI reader.

        Args:
            filename: file name or a list of file names to read.
                if a list of files, verify all the suffixes.
        """
        return is_supported_format(filename, ["tif", "tiff"])

    def read(self, data: Union[Sequence[str], str, np.ndarray], **kwargs):
        """
        Read image data from specified file or files.
        Note that the returned object is CuImage or list of CuImage objects.

        Args:
            data: file name or a list of file names to read.

        """
        img_: List = []

        filenames: Sequence[str] = ensure_tuple(data)
        for name in filenames:
            img = self.wsi_reader(name)
            img_.append(img)

        return img_ if len(filenames) > 1 else img_[0]

    def get_data(
        self,
        img_obj,
        location: Tuple = (0, 0),
        size: Optional[Tuple] = None,
        level: int = 0,
        dtype: Type = np.uint8,
        grid_shape: Union[Tuple[int, int], int] = (1, 1),
        patch_size: Optional[Union[Tuple[int, int], int]] = None,
    ):
        """
        Extract regions as numpy array from WSI image and return them.

        Args:
            img:      a wsi_reader object loaded from a file, or list of CuImage objects
            location: (x_min, y_min) tuple giving the top left pixel in the level 0 reference frame,
                       or list of tuples (default=(0, 0))
            size:     (width, height) tuple giving the region size, or list of tuples (default=(wsi_width, wsi_height))
                        This is the size of image at the given level (`level`)
            level:    the level number, or list of level numbers (default=0)

        """
        if size is None:
            if location == (0, 0):
                # the maximum size is set to WxH
                size = (img_obj.shape[1] // (2 ** level), img_obj.shape[0] // (2 ** level))
                print(f"Size is set to maximum size at level={level}:  {size}")
            else:
                print("Size need to be provided!")
                return
        region = self._extract_region(img_obj, location=location, size=size, level=level, dtype=dtype)
        patches = self._extract_patches(region, patch_size=patch_size, grid_shape=grid_shape, dtype=dtype)
        return patches

    def _extract_region(
        self,
        img_obj,
        location: Tuple = (0, 0),
        size: Optional[Tuple] = None,
        level: int = 0,
        dtype: Type = np.uint8,
    ):
        region = img_obj.read_region(location=location, size=size, level=level)
        if self.wsi_reader_name == "openslide":
            region = region.convert("RGB")
        # convert to numpy
        region = np.asarray(region, dtype=dtype)
        # cuCalaraImage/OpenSlide: (H x W x C) -> torch image: (C X H X W)
        region = region.transpose((2, 0, 1))
        return region

    def _extract_patches(
        self,
        region: np.array,
        grid_shape: Union[Tuple[int, int], int] = (1, 1),
        patch_size: Optional[Union[Tuple[int, int], int]] = None,
        dtype: Type = np.uint8,
    ):
        if patch_size is None and grid_shape == (1, 1):
            return region
        
        if type(grid_shape) == int:
            grid_shape = (grid_shape, grid_shape)

        n_patches = np.prod(grid_shape)
        region_size = region.shape[1:]
        
        if patch_size == None:
            patch_size = (region_size[0] // grid_shape[0], region_size[1] // grid_shape[1])
        elif type(patch_size) == int:
            patch_size = (patch_size, patch_size)

        # split the region into patches on the grid and center crop them to patch size
        flat_patch_grid = np.zeros((n_patches, 3, patch_size[0], patch_size[1]), dtype=dtype)
        start_points = [
            np.round(region_size[i] * (0.5 + np.arange(grid_shape[i])) / grid_shape[i] - patch_size[i] / 2).astype(int)
            for i in range(2)
        ]
        idx = 0
        for y_start in start_points[1]:
            for x_start in start_points[0]:
                x_end = x_start + patch_size[0]
                y_end = y_start + patch_size[1]
                flat_patch_grid[idx] = region[:, x_start:x_end, y_start:y_end]
                idx += 1

        return flat_patch_grid
