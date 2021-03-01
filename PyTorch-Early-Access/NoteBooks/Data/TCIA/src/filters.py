"""List of function to pre-filter dicom slices or series

"""
import re

from src.dicom_keys import DICOM_TAGS_TO_KEEP

ImageType = "ImageType"
CorrectedImage = "CorrectedImage"
Modality = "Modality"
SeriesDescription = "SeriesDescription"
assert ImageType in DICOM_TAGS_TO_KEEP
assert CorrectedImage in DICOM_TAGS_TO_KEEP
assert Modality in DICOM_TAGS_TO_KEEP
assert SeriesDescription in DICOM_TAGS_TO_KEEP


def original_image(metas):
    # specify modality in case dicom rt or seg are not original
    return ("ORIGINAL" in metas[ImageType]) and (metas[Modality] in ["CT", "PT", "MR"])


def attn_corrected(metas):
    if metas[Modality] != "PT":
        return True
    else:
        conds = []
        no_ac_strings = ["noac", "nac", "noattn"]
        if CorrectedImage in metas:
            conds.append("ATTN" in metas[CorrectedImage])
        conds.extend(
            pattern not in re.sub(r'[^A-Za-z0-9]+', '', metas[SeriesDescription]).lower() for pattern in no_ac_strings)
        return all(conds)


def is_ct_rtstruct_seg_mr_pt(metas):
    return metas[Modality] in ["RTSTRUCT", "CT", "PT", "SEG", "MR"]


def keep_slice(metas):
    # return True
    return metas[Modality] in ["SEG"] ## AEH need only seg
    for predicate in (is_ct_rtstruct_seg_mr_pt, original_image, attn_corrected):
        if predicate(metas):
            continue
        else:
            return False
    return True


def small_series(list_of_slices):
    return len(list_of_slices) < 25
