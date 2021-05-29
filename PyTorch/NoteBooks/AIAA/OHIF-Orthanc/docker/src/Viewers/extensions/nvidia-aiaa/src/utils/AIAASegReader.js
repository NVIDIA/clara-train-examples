// SPDX-License-Identifier: Apache-2.0

import nifti from 'nifti-reader-js';
import nrrd from 'nrrd-js';
import pako from 'pako';
import readImageArrayBuffer from 'itk/readImageArrayBuffer';
import writeArrayBuffer from 'itk/writeArrayBuffer';
import config from 'itk/itkConfig';
import cornerstone from "cornerstone-core";
import cornerstoneTools from "cornerstone-tools";
import dcmjs from "dcmjs";
import DICOMWeb from "@ohif/core/src/DICOMWeb";
import errorHandler from "@ohif/core/src/errorHandler";
import {api} from "dicomweb-client";

const pkgJSON = require('../../package.json');
const itkVersion = pkgJSON.dependencies.itk.substring(1);
config.itkModulesPath = 'https://unpkg.com/itk@' + itkVersion; // HACK to use ITK from CDN

export default class AIAASegReader {
  static parseNiftiData(data) {
    if (nifti.isCompressed(data)) {
      data = nifti.decompress(data);
    }
    if (!nifti.isNIFTI(data)) {
      throw Error('Invalid NIFTI Data');
    }

    const header = nifti.readHeader(data);
    const image = nifti.readImage(header, data);
    console.debug(header.toFormattedString());

    return {
      header,
      image,
    };
  }
  //##########################################################################################
  static parseNrrdData(data) {
    let nrrdfile = nrrd.parse(data);

    // Currently gzip is not supported in nrrd.js
    if (nrrdfile.encoding === 'gzip') {
      const buffer = pako.inflate(nrrdfile.buffer).buffer;

      nrrdfile.encoding = 'raw';
      nrrdfile.data = new Uint16Array(buffer);
      nrrdfile.buffer = buffer;
    }

    const image = nrrdfile.buffer;
    const header = nrrdfile;
    delete header.data;
    delete header.buffer;

    return {
      header,
      image,
    };
  }
  //##########################################################################################
  static saveFile(blob, filename) {
    if (window.navigator.msSaveOrOpenBlob) {
      window.navigator.msSaveOrOpenBlob(blob, filename);
    } else {
      const a = document.createElement('a');
      document.body.appendChild(a);

      const url = window.URL.createObjectURL(blob);
      a.href = url;
      a.download = filename;
      a.click();

      setTimeout(() => {
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
      }, 0);
    }
  };
  //##########################################################################################
  //AEH change here to change the seg
  static serializeDicomSeg(images, labelmaps3D, filename) {
    const segmentationModule = cornerstoneTools.getModule('segmentation');
    const lastSlNumber=images.length;
    console.info( '====================== AEH 0 lastSlNumber=',lastSlNumber);

    for (let labelmapIndex = 0; labelmapIndex < labelmaps3D.length; labelmapIndex++) {
      const labelmap3D = labelmaps3D[labelmapIndex];
      const colorLutTable = segmentationModule.state.colorLutTables[labelmap3D.colorLUTIndex];
      if (labelmap3D && labelmap3D.metadata && labelmap3D.metadata.data) {
        const data = labelmap3D.metadata.data; // AEH Seems the labelmap3D.metadata.data is already placed in when coloring

        console.info( 'AEH data',data);
        for (let i = 1; i < data.length; i++) {
          console.info('AEH 01  i=',i,' to data.length',data.length);
          console.info( 'AEH data[i]',data[i]);
          let i_zerobased= i-1;
          //data[i].RecommendedDisplayCIELabValue = dcmjs.data.Colors.rgb2DICOMLAB(colorLutTable[i]);
          data[i].ROIDisplayColor = colorLutTable[i].slice(0, 3);
          if (!data[i].SegmentDescription) {
            data[i].SegmentDescription = data[i].SegmentLabel;
          }
          labelmap3D.metadata = data;


          ////////////////////////////// AEH added code
          /// AEH need to add 1 pixel to first and last slice
          let labelmaps2D = labelmaps3D[i_zerobased].labelmaps2D;
          let reversedlabelmaps2D =[];
          console.info( 'AEH labelmaps2D=',labelmaps2D);
          console.info('----- bug  AEH 01 labelmaps3D ',labelmaps3D[0].labelmaps2D);

          var pixelArrLength;
          for (let j = 0; j < labelmaps2D.length; j++) {
            if (labelmaps2D[j]!= null){
              console.info( 'AEH 05 i,j=',i,j);
              pixelArrLength=labelmaps2D[j].pixelData.length;
              labelmaps2D[j].segmentsOnLabelmap=[0,1]; // just to make sure some remain empty may be causing the errors!
              reversedlabelmaps2D[lastSlNumber-j-1]=labelmaps2D[j];
            }
          }
          console.info('pixelArrLength ',pixelArrLength);
          console.info('AEH 04 reversedlabelmaps2D ',reversedlabelmaps2D );
          // Add first and last slice into the labels with 1 pixel marked
          for (let j of [ 0, lastSlNumber - 1] ) {
            console.info('AEH 1 ');
            var tmp = {
                pixelData: new Uint16Array(pixelArrLength),
                segmentsOnLabelmap: [0, 1]
                };
            tmp.pixelData[i] = 1; // just assigning different pixel for each label
            labelmaps2D[j] = tmp;
            reversedlabelmaps2D[j]=tmp;
            console.info('AEH reversedlabelmaps2D[j] in loop ',reversedlabelmaps2D[j] );
            console.info('----- bug  AEH 06 labelmaps3D ',labelmaps3D[0].labelmaps2D);
          }
          console.info('AEH 08 reversedlabelmaps2D ',reversedlabelmaps2D );
          // labelmaps3D[i_zerobased].labelmaps2D =labelmaps2D; // i is 1 based ?? not sure why
          labelmaps3D[i_zerobased].labelmaps2D =reversedlabelmaps2D; // i is 1 based ?? not sure why
          console.info('----- bug  AEH 08 labelmaps3D ',labelmaps3D[0].labelmaps2D);
        }
      }
    }

    console.info('================== AEH 20 after loop');
    console.info('----- bug  AEH 21 labelmaps3D ',labelmaps3D[0].labelmaps2D);
    console.info('AEH 22 labelmaps3D',labelmaps3D);
    console.info( 'AEH images',images );
    // var reverseImages=images.reverse();
    // console.info('AEH reverse  ',reverseImages );

    // AEH Yuan-ting fix
    //const segBlob = dcmjs.adapters.Cornerstone.Segmentation.generateSegmentation(images, labelmaps3D);
    const segBlob = dcmjs.adapters.Cornerstone.Segmentation.generateSegmentation(images, labelmaps3D, {includeSliceSpacing: true, rleEncode: false});
    //AIAASegReader.saveFile(new Blob([segBlob]), filename);
    //console.info('File downloaded: ' + filename);
    console.info('================== AEH 30 after dcmjs');

    const config = {
      url: window.config.servers.dicomWeb[0].wadoRoot,
      headers: DICOMWeb.getAuthorizationHeader(),
      errorInterceptor: errorHandler.getHTTPErrorHandler(),
    };
    console.info('================== AEH 40 ');

    const dicomWeb = new api.DICOMwebClient(config);
    segBlob.arrayBuffer().then(function (buffer) {
      const options = {
        datasets: [buffer],
      };
      dicomWeb.storeInstances(options);
    });
    console.info('================== AEH 50 ');

    for (let labelmapIndex = 0; labelmapIndex < labelmaps3D.length; labelmapIndex++) {
      const labelmap3D = labelmaps3D[labelmapIndex];
      if (labelmap3D && labelmap3D.metadata) {
        const data = labelmap3D.metadata;
        labelmap3D.metadata = {data: data};
      }
    }
    console.info('================== AEH 60 ');

  }
  //##########################################################################################
  // https://insightsoftwareconsortium.github.io/itk-js/api/browser_io.html
  static serializeNrrdToNii(header, image, filename) {
    const nrrdBuffer = AIAASegReader.serializeNrrd(header, image);

    const reader = readImageArrayBuffer(null, nrrdBuffer, 'temp.nrrd');
    reader.then(function(response) {
      const writer = writeArrayBuffer(response.webWorker, true, response.image, filename);
      writer.then(function(response) {
        AIAASegReader.saveFile(new Blob([response.arrayBuffer]), filename);
        console.info('File downloaded: ' + filename);
      });
    });
  }
  //##########################################################################################
  // GZIP write not supported by nrrd-js (so use ITK save with compressed = true)
  static serializeNrrdCompressed(header, image, filename) {
    const nrrdBuffer = AIAASegReader.serializeNrrd(header, image);

    const reader = readImageArrayBuffer(null, nrrdBuffer, 'temp.nrrd');
    reader.then(function(response) {
      const writer = writeArrayBuffer(response.webWorker, true, response.image, filename);
      writer.then(function(response) {
        AIAASegReader.saveFile(new Blob([response.arrayBuffer]), filename);
        console.info('File downloaded: ' + filename);
      });
    });
  }
  //##########################################################################################
  static serializeNrrd(header, image, filename) {
    let nrrdOrg = Object.assign({}, header);
    nrrdOrg.buffer = image;
    nrrdOrg.data = new Uint16Array(image);

    const nrrdBuffer = nrrd.serialize(nrrdOrg);
    if (filename) {
      AIAASegReader.saveFile(new Blob([nrrdBuffer]), filename);
      console.info('File downloaded: ' + filename);
    }
    return nrrdBuffer;
  }
}
