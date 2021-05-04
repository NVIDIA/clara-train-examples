import argparse
import logging

import numpy as np
from monai.data.image_reader import WSIReader
from skimage.color import rgb2hsv
from skimage.filters import threshold_otsu


def create_masks(args):
    logging.basicConfig(level=logging.INFO)

    reader = WSIReader(reader_lib="cuCIM")
    img_obj = reader.read(args.wsi_path)
    img_rgb, _ = reader.get_data(img_obj, level=args.level)
    img_hsv = rgb2hsv(img_rgb.transpose(1, 2, 0))

    background_R = img_rgb[0] > threshold_otsu(img_rgb[0])
    background_G = img_rgb[1] > threshold_otsu(img_rgb[1])
    background_B = img_rgb[2] > threshold_otsu(img_rgb[2])
    tissue_RGB = np.logical_not(background_R & background_G & background_B)
    tissue_S = img_hsv[..., 1] > threshold_otsu(img_hsv[..., 1])
    min_R = img_rgb[0] > args.RGB_min
    min_G = img_rgb[1] > args.RGB_min
    min_B = img_rgb[2] > args.RGB_min

    tissue_mask = tissue_S & tissue_RGB & min_R & min_G & min_B
    np.save(args.npy_path, tissue_mask)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create tissue masks of WSI and save it in numpy array.")
    parser.add_argument(
        "wsi_path",
        default=None,
        metavar="WSI_PATH",
        type=str,
        help="Path to the directory containing WSI files for testing.",
    )
    parser.add_argument(
        "npy_path",
        default=None,
        metavar="NPY_PATH",
        type=str,
        help="Path to the output directory for numpy tissue masks.",
    )
    parser.add_argument(
        "--level",
        default=6,
        type=int,
        help="at which WSI level" " to obtain the mask, default 6",
    )
    parser.add_argument("--RGB_min", default=50, type=int, help="min value for RGB" " channel, default 50")

    args = parser.parse_args()
    create_masks(args)
