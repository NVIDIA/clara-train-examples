// SPDX-License-Identifier: Apache-2.0

import React from 'react';
import AIAAPanel from './components/AIAAPanel.js';

const panelModule = ({ servicesManager, commandsManager }) => {
  // TODO:: How get the following and sent it to AIAAPanel (is it needed? may be there is another way to invoke services)
  /*
  const { UINotificationService } = servicesManager.services;

  const studies = [];
  const viewports = [];
  const activeIndex = 0;

  const ConnectedAIAAPanel = () => (
    <AIAAPanel
      studies={studies}
      viewports={viewports}
      activeIndex={activeIndex}

      onComplete={message => {
        if (UINotificationService) UINotificationService.show(message);
      }}
      onSegmentation={model_name => {
        commandsManager.runCommand('segmentation', {
          model_name: model_name,
        });
      }}
      onAnnotation={model_name => {
        commandsManager.runCommand('dextr3d', {
          model_name: model_name,
        });
      }}
      onDeepgrow={model_name => {
        commandsManager.runCommand('deepgrow', {
          model_name: model_name,
        });
      }}
    />
  );
  */

  return {
    menuOptions: [
      {
        icon: 'list',
        label: 'NVIDIA AIAA',
        from: 'right',
        target: 'nvidia-aiaa-panel',
      },
    ],
    components: [
      {
        id: 'nvidia-aiaa-panel',
        component: AIAAPanel,
      },
    ],
    defaultContext: ['VIEWER'],
  };
};

export default panelModule;
