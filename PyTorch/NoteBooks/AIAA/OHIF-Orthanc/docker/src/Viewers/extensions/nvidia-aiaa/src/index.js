// SPDX-License-Identifier: Apache-2.0

import toolbarModule from './toolbarModule';
import panelModule from './panelModule.js';
import init from './init';
import { DeepgrowProbeTool, DExtr3DProbeTool } from './utils/AIAAProbeTool';

export { DeepgrowProbeTool, DExtr3DProbeTool };

export default {
  id: 'com.ohif.nvidia-aiaa',

  preRegistration({ servicesManager, configuration = {} }) {
    init({ servicesManager, configuration });
  },
  getToolbarModule({ servicesManager }) {
    return toolbarModule;
  },
  getPanelModule({ servicesManager, commandsManager }) {
    return panelModule({ servicesManager, commandsManager });
  },
};
