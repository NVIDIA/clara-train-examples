// SPDX-License-Identifier: Apache-2.0

const commandsModule = ({ servicesManager }) => {
  const { AIAAService, UINotificationService } = servicesManager.services;
  const { volume, client } = AIAAService;

  const AIAAshow = (message, type = 'success', debug = true) => {
    if (debug) {
      console.log('NVIDIA AIAA - ' + message);
    }
    if (UINotificationService) {
      UINotificationService.show({
        title: 'NVIDIA AIAA',
        message: message,
        type: type,
      });
    }
  };

  const actions = {
    segmentation: ({ viewports, model_name }) => {
      AIAAshow('Running segmentation API with ' + model_name);

      volume.getOrCreate(viewports).then(dataBuf => {
        const niiArr = volume.buffer2NiiArr(dataBuf);
        const blob = new Blob([niiArr], { type: 'application/octet-stream' });
        client
          .segmentation(model_name, blob)
          .then(response => {
            var niiBufferArr = response.data;
            if (niiBufferArr == undefined) {
              AIAAshow(
                'Server didn\'t return data. Check AIAA server logs',
                'error',
              );
              return;
            }
            //const seriesInstanceUid = OHIF.NVIDIA.dataArg.seriesInstanceUid;
            //const maskImporter = new MaskImporter(seriesInstanceUid);
            //maskImporter.importNIFTI(niiBufferArr);
            AIAAshow('Segmentation completed');
          })
          .catch(e => AIAAshow(e, 'error'));
      });
    },
    dextr3d: ({ viewports, model_name }) => {
      AIAAshow('Running dextr3d API with ' + model_name);
    },
    deepgrow: ({ viewports, model_name }) => {
      AIAAshow('Running deepgrow API with ' + model_name);
    },
  };

  const definitions = {
    segmentation: {
      commandFn: actions.segmentation,
      storeContexts: ['viewports'],
      options: {},
    },
    dextr3d: {
      commandFn: actions.dextr3d,
      storeContexts: ['viewports'],
      options: {},
    },
    deepgrow: {
      commandFn: actions.deepgrow,
      storeContexts: ['viewports'],
      options: {},
    },
  };

  return {
    definitions,
    defaultContext: 'ACTIVE_VIEWPORT::CORNERSTONE',
  };
};

export default commandsModule;
