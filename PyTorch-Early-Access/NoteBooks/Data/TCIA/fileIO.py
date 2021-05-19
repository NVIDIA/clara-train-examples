from os import path
import nibabel as nib
import numpy as np


###################################################################################
# nifti files
###################################################################################
def openNifti(fname,type=None):
    '''
    :param fname: file path to open
    :return: imgNp: numpy
             hdr: info
    '''
    assert path.isfile(fname), "file doesn't exist "+fname

    img = nib.load(fname)
    imgNp = img.get_fdata()
    if type is not None:
        imgNp=imgNp.astype(type)
    # imgNp.shape
    hdr = img.header
    return imgNp, hdr


def writeNifti(dataNp, fname,affineNp):
    '''
    :param dataNp: np to write
    :param fname:  file name to write to
    :param affineNp:  affine transformation to use. usually from hdr.get_base_affine()
    :return:
    '''
    # data = np.ones((32, 32, 15, 100), dtype=np.int16)
    if dataNp.dtype == np.bool: #or dataNp.dtype == np.uint8:
        img = nib.Nifti1Image(dataNp.astype(np.uint8), affineNp)
    else:
        img = nib.Nifti1Image(dataNp, affineNp)
    img.to_filename(fname)
    # nib.save(img, fname)


###################################################################################
# json for datalist
###################################################################################
import json
import os

class DataJson():
    def __init__(self, dataRoot="",file2Load=None):
        self._jsonData = {}
        self._rootPath = dataRoot
        self._jsonData['rootPath'] = self._rootPath
        if file2Load is not None:
            self._load(file2Load)
        else:
            self._jsonData['training'] = []

    def appendDataPt(self, img, gt,checkFileExist=True):
        if checkFileExist:
            f=self._rootPath+img
            assert os.path.isfile(f) , "files "+f+" doesn't exist"
            f = self._rootPath + gt
            assert os.path.isfile(f), "files " + f + " doesn't exist"
        self._jsonData['training'].append({
            "image": img,
            "label": gt
        })
        print("adding img",img," gt ",gt)

    def write2file(self, filename):
        with open(filename, 'w') as outfile:
            json.dump(self._jsonData, outfile)
        print("written file to disk with {} items in Training".format(self.getNumItem()))
        # print("and {} items in validation".format(self.getNumItem("validation")))
    def getJson(self):
        return self._jsonData
    def getNumItem(self,dictItem="training"):
        return len(self._jsonData[dictItem])
    def getItemAt(self,index=0,key='image',dictItem="training"):
        return self._jsonData["rootPath"]+self._jsonData[dictItem][index][key]
    def _load(self,filePath):
        with open(filePath, 'r') as f:
            self._jsonData = json.load(f)

    def _print4debug(self,dictItem="training"):
        root=self._jsonData["rootPath"]
        print(root)
        for itm in self._jsonData[dictItem]:
            # print(root+itm["image"])
            print(root+itm["label"])
            print(os.path.basename(root+itm["label"]))

