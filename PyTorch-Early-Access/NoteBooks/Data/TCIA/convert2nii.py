import argparse
from pathlib import Path
import logging
import os
import glob
import fileIO
import numpy as np
from time import sleep
import json
from src import create_csv_db

LOGGING_LEVEL = logging.INFO
# LOGGING_LEVEL=logging.DEBUG
# logging.basicConfig(level=LOGGING_LEVEL)
logging.basicConfig(level=LOGGING_LEVEL,
                    format='[%(asctime)s.%(msecs)03d][%(levelname)5s](%(name)s:%(funcName)s) - %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S')
SERIES_INST_UID_APPEND_TO_SEG_FNAME=6

def runOScmd(cmd):
    logging.info("cmd to run  cmd= {}".format(cmd))
    os.system(cmd)

def convertDcm2nii(source, outputDir):
    runOScmd("medl-dataconvert --src_ext .dcm --dst_ext .nii.gz --output " + outputDir + " --dir " + source)

def covertAllSeg2Nifti(df, outputDir,flipAxis):
    lbKeyDic = {}
    for ds in df:
        # print(ds)
        seg_Series_IUID=ds['SeriesInstanceUID']
        PatientID = ds['PatientID']
        filePath = ds['file_location']
        RefDicomIUID = ds['ReferencedSeriesSequence0_SeriesInstanceUID']
        RefDicomIUID = RefDicomIUID.replace("'", "")
        print("ref2 fetch=", filePath)
        # create folder for each patient
        # patOutputDir = outputDir +"/"+PatientID
        # os.makedirs(patOutputDir, exist_ok=True)
        fileNameFormat = RefDicomIUID + "_" + seg_Series_IUID[-SERIES_INST_UID_APPEND_TO_SEG_FNAME:] + "_seg.nii.gz"
        fileNameFormat = PatientID + "_seg_"+seg_Series_IUID[-SERIES_INST_UID_APPEND_TO_SEG_FNAME:]+".nii.gz"
        outputFilePath = outputDir + "/" + fileNameFormat.replace("'","") # remove some ' that are in the seg file name
        covertSeg2Nii(filePath, outputFilePath, lbKeyDic,tmp_path=outputDir+"/../tmp/",flipAxis=flipAxis)

def covertSeg2Nii(filePath, outputFilePath, lbKeyDic,tmp_path,flipAxis):
    print("Converting Seg from Location =", filePath)
    # tmp_path = outputFilePath+"/../tmp/"
    os.makedirs(tmp_path, exist_ok=True)
    runOScmd("rm " + tmp_path + "/*")
    sleep(1)
    runOScmd("segimage2itkimage -t nii --outputDirectory " + tmp_path + " --inputDICOM " + filePath)
    metaFile= tmp_path + "meta.json"
    file2IdDic=readSegMetaJson(metaFile,lbKeyDic)
    mergeMultipleNiftis(tmp_path, outputFilePath, file2IdDic,flipAxis)


def mergeMultipleNiftis(tmp_path, outputFilePath, file2IdDic,flipAxis):
    # simple merge by file name doesn't work since labels are continues numbers and can be for different labels
    # Need to read the json to know what label is what number
    allNP = None
    for fileName in file2IdDic:
        segment_number = file2IdDic[fileName]
        print(fileName, '->', segment_number)
        # files = glob.glob(tmp_path+"/*.nii.gz")
        # for segment_number,f in enumerate(files):
        fPath = tmp_path + "/" + fileName
        print("Merging nii files =", fPath)
        imgNp, hdr = fileIO.openNifti(fPath)
        if allNP is None:
            allNP = np.zeros_like(imgNp, dtype=np.uint8)
        allNP[imgNp > 0] = segment_number

    if "rot" in flipAxis or flipAxis=="all":
        allNP = np.swapaxes(allNP , 0,1) # rotate on axial
    if "lr" in flipAxis or flipAxis=="all":
        allNP = np.flip(allNP, axis=0) #lr
    if "ap" in flipAxis or flipAxis=="all":
        allNP = np.flip(allNP, axis=1) # ap
    if "si" in flipAxis or flipAxis=="all":
        allNP = np.flip(allNP, axis=2) # si
    print("writing mergeged file as", outputFilePath)

    # normal file name
    fileIO.writeNifti(allNP, outputFilePath[:outputFilePath.find("_seg_") + 4] + ".nii.gz", hdr.get_base_affine())
    # file name with Ser UID appended
    fileIO.writeNifti(allNP, outputFilePath, hdr.get_base_affine())
    # file after removing 1 slice
    fileIO.writeNifti(allNP[:,:,:-1], outputFilePath.replace("_seg","_seg_ShortZ"), hdr.get_base_affine())


# def mergeMultipleNiftis_old(tmp_path, outputFilePath):
#     # simple merge by file name doesn't work since labels are continues numbers and can be for different labels
#     # Need to read the
#     files = glob.glob(tmp_path + "/*.nii.gz")
#     allNP = None
#     for segment_number, f in enumerate(files):
#         print("Merging nii files =", f)
#         imgNp, hdr = fileIO.openNifti(f)
#         if allNP is None:
#             allNP = np.zeros_like(imgNp, dtype=np.uint8)
#         allNP[imgNp > 0] = segment_number
#
#         # allNP = np.flip(allNP, axis=0)
#     print("writing mergeged file as", outputFilePath)
#     fileIO.writeNifti(allNP, outputFilePath, hdr.get_base_affine())


def readSegMetaJson(filePath, lbKeyDic):
    # this function will add to lbkeyDic the is inputed
    # will return dic of ids and what label to use for it
    ## {2.nii:1, 1.nii:2, 3.nii:4}
    with open(filePath) as f:
        data = json.load(f)
    segmentAttributes = data['segmentAttributes']
    file2IdDic = {}
    for s in segmentAttributes:
        s0 = s[0]
        id = str(s0['labelID'])
        lbName = s0['SegmentLabel']
        lbDesc = s0['SegmentDescription']
        fName = id + ".nii.gz"
        print("id=", id, " lb Name=", lbName, " lb desc", lbDesc, " file=", fName)
        if lbDesc not in lbKeyDic.keys():
            lbKeyDic[lbDesc] = id
        # key are now already there but could have another id
        file2IdDic[ id + ".nii.gz"] = lbKeyDic[lbDesc]
    return file2IdDic


def main():
    # filePath="/claraDevDay/Data/tcia_downloader-master/test_NSCLC/1/"
    # lbKeyDic={}
    # file2IdDic=readSegMetaJson(filePath+"meta_1.json",lbKeyDic)
    # mergeMultipleNiftis(file2IdDic)
    # file2IdDic=readSegMetaJson(filePath+"meta.json",lbKeyDic)
    # mergeMultipleNiftis(file2IdDic)
    # return
    parser = argparse.ArgumentParser()
    parser.add_argument("source", help="the root folder where to recursively search and analyse dicom filess")
    parser.add_argument("--jobs", "-j", help="Number of workers to use", default=4, type=int)
    parser.add_argument("--filter_small_series", help="filter series with less than 25 slices in it", action="store_true")
    parser.add_argument("--filter_slices", help="keep only CT,MR,AC PT,RTSTRUC and SEG, original acquisition only", default=True,action="store_true")
    parser.add_argument("--outputDir", "-o", help="Output Directory for converted files ", default="./output", type=str)
    parser.add_argument("--dicomConvert", "-d", help="Convert dicom to nii ", default=False,action="store_true")
    parser.add_argument("--flipAxis", "-f", help="Flips axes [ap,lr,si,rot]", default="",type=str,choices=['ap','lr','si','rot',"all",'rotsi','rotsilr','apsi'])

    args = parser.parse_args()
    print(args)
    print("args.filter_slices" + str(args.filter_slices))
    if args.dicomConvert:
        convertDcm2nii(args.source,args.outputDir)
    else:
        final_list_of_mdatas = create_csv_db.extract_dcm_metadata_to_csv(Path(args.source), args.jobs, args.filter_slices, args.filter_small_series)
        covertAllSeg2Nifti(final_list_of_mdatas, args.outputDir,args.flipAxis)


if __name__ == '__main__':
    main()
    print("---------------Done ")
