// SPDX-License-Identifier: Apache-2.0

import cornerstone from 'cornerstone-core';
import cornerstoneTools from 'cornerstone-tools';
import OHIF from '@ohif/core';
import ndarray from 'ndarray';

var arrayBufferConcat = require('arraybuffer-concat');
const { DicomLoaderService } = OHIF.utils;

export default class AIAAVolume {
  constructor() {
    this.metadata = {
      seriesInstanceUid: '',
      nSlices: 0,
      slope: 1,
      intercept: 0,
      rows: 0,
      columns: 0,
      columnPixelSpacing: 0,
      rowPixelSpacing: 0,
      seriesDescription: '',
    };
    this.volume = null;
  }

  createDicomData = async (studies, StudyInstanceUID, SeriesInstanceUID, flag = false) => {
    console.info('createDicomData this takes some time .......');
    const study = studies.find(
      study => study.StudyInstanceUID === StudyInstanceUID,
    );

    const displaySets = study.displaySets.filter(displaySet => {
      return displaySet.SeriesInstanceUID === SeriesInstanceUID;
    });

    if (displaySets.length > 1) {
      console.warn('More than one display set with the same SeriesInstanceUID. This is not supported yet...');
    }

    // TODO:: Remove this hack; Instead of fetching it again, get it from imageCache
    const d = displaySets[0];
    let n = {
      displaySetInstanceUID: d.displaySetInstanceUID,
      SeriesDate: d.SeriesDate,
      SeriesTime: d.SeriesTime,
      SeriesInstanceUID: d.SeriesInstanceUID,
      SeriesNumber: d.SeriesNumber,
      SeriesDescription: d.SeriesDescription,
      numImageFrames: d.numImageFrames,
      frameRate: d.frameRate,
      Modality: d.Modality,
      isMultiFrame: d.isMultiFrame,
      InstanceNumber: d.InstanceNumber,
      isReconstructable: d.isReconstructable,
      StudyInstanceUID: d.StudyInstanceUID,
      sopClassUIDs: d.sopClassUIDs,
      plugin: 'cornerstone',
      images: [],
    };

    // HACK:: DicomLoaderService.findDicomDataPromise only reads first image from ImageSet
    let imagesBuffers = [];
    for (let i = 0; i < d.images.length; i++) {
      n.images = [];
      n.images.push(d.images[i]);
      for (let j = 0; j < d.images.length; j++) {
        if (i === j) {
          continue;
        }
        n.images.push(d.images[j]);
      }

      console.info('Getting Dicom for: ' + i);
      const volume = await DicomLoaderService.findDicomDataPromise(n, studies);
      if (flag) {
        imagesBuffers.push({data: {byteArray: new Uint8Array(volume)}, imageId: d.images[i]._imageId});
      } else {
        let image_in = new Blob([volume], { type: 'application/octet-stream' });
        imagesBuffers.push({data: image_in, name: 'image_' + i + '.dcm'});
      }
    }

    return imagesBuffers;
  };

  createNiftiData = async () => {
    console.info('createNiftiData this takes some time .......');

    // TODO: How to get correct stackState here
    let elements = cornerstone.getEnabledElements();
    const element = elements[0].element;
    const stackState = cornerstoneTools.getToolState(element, 'stack');

    // all of the image ids
    const imageIds = stackState.data[0].imageIds;
    this.metadata.nSlices = imageIds.length;

    const loadImagePromises = imageIds.map(cornerstone.loadAndCacheImage);
    let a;

    try {
      const images = await Promise.all(loadImagePromises);
      let firstImage = images[0];

      this.metadata.slope = firstImage.slope;
      this.metadata.intercept = firstImage.intercept;
      this.metadata.rows = firstImage.rows;
      this.metadata.columns = firstImage.columns;
      this.metadata.rowPixelSpacing = firstImage.rowPixelSpacing;
      this.metadata.columnPixelSpacing = firstImage.columnPixelSpacing;

      // TODO (Yuan-Ting): How to get correct slice thickness from OHIF?
      this.metadata.sliceThickness = firstImage.sliceThickness;
      if (this.metadata.sliceThickness === undefined) {
        this.metadata.sliceThickness = 1;
      }

      // TODO (Yuan-Ting): How to get correct image position patient from OHIF?
      this.metadata.imagePositionPatient = firstImage.imagePositionPatient;
      if (this.metadata.imagePositionPatient === undefined) {
        this.metadata.imagePositionPatient = {
          x: 0,
          y: 0,
          z: 0,
        };
        console.debug('Data error, no imagePositionPatient in metadata!');
      }

      const x = this.metadata.columns;
      const y = this.metadata.rows;
      const z = this.metadata.nSlices;

      a = new Int16Array(x * y * z);
      for (let i = 0; i < z; i++) {
        let slPix = images[i].getPixelData();
        for (let j = 0; j < x * y; j++) {
          a[i * x * y + j] = slPix[j];
        }
      }
      console.info('createNiftiData completed .......');

      let niiArray = this.buffer2NiiArr(a);
      let image_in = new Blob([niiArray], { type: 'application/octet-stream' });
      return { data: image_in, name: 'image.nii' };
    } catch (error) {
      console.error('Error in createNiftiData ' + error);
    }
  };

  buffer2NiiArr = (buff) => {
    const resolution = [
      this.metadata.rowPixelSpacing,
      this.metadata.columnPixelSpacing,
      this.metadata.sliceThickness,
    ];

    const x = this.metadata.columns;
    const y = this.metadata.rows;
    const z = this.metadata.nSlices;
    const volDim = [z, x, y];

    let array = ndarray(buff, volDim);
    const niiArray = this.serializeNifti(
      array,
      resolution,
      this.metadata.imagePositionPatient,
      this.metadata.slope,
      this.metadata.intercept,
    );
    return niiArray;
  };

  /**
   * Add NIFTI-1 related headers to an image buffer to create an raw byte array
   * of NIFTI file.
   */
  serializeNifti = (
    dst_array,
    resolution,
    imagePositionPatient,
    slope = 1,
    intercept = 0,
  ) => {
    let buffer = new ArrayBuffer(352); //header of the nifty file 352 bytes for any nifti
    for (let i = 0; i < buffer.byteLength; ++i) {
      buffer[i] = 0;
    }

    // read https://brainder.org/2012/09/23/the-nifti-file-format/

    let headerLength = new Int32Array(buffer, 0, 1);
    let dim = new Int16Array(buffer, 40, 8);
    let datatype = new Int16Array(buffer, 70, 1);
    let bitpix = new Int16Array(buffer, 72, 1);
    let pixdim = new Float32Array(buffer, 76, 8);
    let voxoffset = new Float32Array(buffer, 108, 1);
    let scl_slope = new Float32Array(buffer, 112, 1);
    let scl_inter = new Float32Array(buffer, 116, 1);
    let xyzt_units = new Int8Array(buffer, 123, 1);

    let qform_sform = new Int16Array(buffer, 252, 1);
    let sform_code = new Int16Array(buffer, 254, 1);
    let qoffset_x = new Float32Array(buffer, 268, 1);
    let qoffset_y = new Float32Array(buffer, 272, 1);
    let qoffset_z = new Float32Array(buffer, 276, 1);
    let tform = new Float32Array(buffer, 280, 12);
    let magic = new Uint8Array(buffer, 344, 4);

    headerLength[0] = 348;

    dim[0] = 3;
    dim[1] = dst_array.shape[2];
    dim[2] = dst_array.shape[1];
    dim[3] = dst_array.shape[0];
    dim[4] = 1;
    dim[5] = 1;
    dim[6] = 1;
    dim[7] = 1;

    let code_BitPix = [4, 16];
    datatype[0] = code_BitPix[0];
    bitpix[0] = code_BitPix[1];
    pixdim[0] = 1;
    pixdim[1] = resolution[0];
    pixdim[2] = resolution[1];
    pixdim[3] = resolution[2];

    voxoffset[0] = 352; // where real data starts in float format (according to above)

    // scl_slope[0] = 1;

    scl_slope[0] = slope;
    scl_inter[0] = intercept;
    qoffset_x[0] = -imagePositionPatient.x;
    qoffset_y[0] = -imagePositionPatient.y;
    qoffset_z[0] = -imagePositionPatient.z;
    xyzt_units[0] = 10; // as original file

    qform_sform[0] = 0;
    sform_code[0] = 2; //1;

    // discard transform for now

    tform[0] = -1.0 * resolution[0];
    tform[5] = -1.0 * resolution[1];
    tform[10] = -1.0 * resolution[2];
    tform[3] = -imagePositionPatient.x;
    tform[7] = -imagePositionPatient.y;
    tform[11] = imagePositionPatient.z;
    magic[0] = 110;
    magic[1] = 43;
    magic[2] = 49;
    magic[3] = 0;

    let result = arrayBufferConcat(buffer, dst_array.data);
    return result;
  };
}
