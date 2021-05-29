// SPDX-License-Identifier: Apache-2.0

const TOOLBAR_BUTTON_TYPES = {
  COMMAND: 'command',
  SET_TOOL_ACTIVE: 'setToolActive',
  BUILT_IN: 'builtIn',
};

const definitions = [
  /*{
    id: 'NvidiaAIAA',
    label: 'NVIDIA AIAA',
    icon: 'ellipse-circle',
    buttons: [
      {
        id: 'DExtr3D',
        label: 'DExtr3D',
        icon: 'liver',
        type: TOOLBAR_BUTTON_TYPES.SET_TOOL_ACTIVE,
        commandName: 'setToolActive',
        commandOptions: { toolName: 'DExtr3DProbeTool' },
      },
      {
        id: 'Deepgrow',
        label: 'Deepgrow',
        icon: 'dot-circle',
        type: TOOLBAR_BUTTON_TYPES.SET_TOOL_ACTIVE,
        commandName: 'setToolActive',
        commandOptions: { toolName: 'DeepgrowProbeTool' },
      }
    ]
  },*/
  {
    id: 'SegTools',
    label: 'Segmentation',
    icon: 'ellipse-circle',
    buttons: [
      {
        id: 'Brush',
        label: 'Brush',
        icon: 'brush',
        type: TOOLBAR_BUTTON_TYPES.SET_TOOL_ACTIVE,
        commandName: 'setToolActive',
        commandOptions: { toolName: 'Brush' },
      },
      {
        id: 'SphericalBrush',
        label: 'Spherical',
        icon: 'sphere',
        type: TOOLBAR_BUTTON_TYPES.SET_TOOL_ACTIVE,
        commandName: 'setToolActive',
        commandOptions: { toolName: 'SphericalBrush' },
      },
      {
        id: 'CircleScissors',
        label: 'Circle',
        icon: 'circle',
        type: TOOLBAR_BUTTON_TYPES.SET_TOOL_ACTIVE,
        commandName: 'setToolActive',
        commandOptions: { toolName: 'CircleScissors' },
      },
      {
        id: 'CircleScissorsEraser',
        label: 'Circle',
        icon: 'circle-o',
        type: TOOLBAR_BUTTON_TYPES.SET_TOOL_ACTIVE,
        commandName: 'setToolActive',
        commandOptions: { toolName: 'CircleScissorsEraser' },
      },
      {
        id: 'FreehandScissors',
        label: 'Freehand',
        icon: 'inline-edit',
        type: TOOLBAR_BUTTON_TYPES.SET_TOOL_ACTIVE,
        commandName: 'setToolActive',
        commandOptions: { toolName: 'FreehandScissors' },
      },
      {
        id: 'FreehandScissorsEraser',
        label: 'Freehand',
        icon: 'liver',
        type: TOOLBAR_BUTTON_TYPES.SET_TOOL_ACTIVE,
        commandName: 'setToolActive',
        commandOptions: { toolName: 'FreehandScissorsEraser' },
      },
      {
        id: 'RectangleScissors',
        label: 'Rectangle',
        icon: 'stop',
        type: TOOLBAR_BUTTON_TYPES.SET_TOOL_ACTIVE,
        commandName: 'setToolActive',
        commandOptions: { toolName: 'RectangleScissors' },
      },
      {
        id: 'RectangleScissorsEraser',
        label: 'Rectangle',
        icon: 'square-o',
        type: TOOLBAR_BUTTON_TYPES.SET_TOOL_ACTIVE,
        commandName: 'setToolActive',
        commandOptions: { toolName: 'RectangleScissorsEraser' },
      },
      {
        id: 'CorrectionScissors',
        label: 'Correction Scissors',
        icon: 'scissors',
        type: TOOLBAR_BUTTON_TYPES.SET_TOOL_ACTIVE,
        commandName: 'setToolActive',
        commandOptions: { toolName: 'CorrectionScissors' },
      },
      {
        id: 'BrushEraser',
        label: 'Eraser',
        icon: 'trash',
        type: TOOLBAR_BUTTON_TYPES.SET_TOOL_ACTIVE,
        commandName: 'setToolActive',
        commandOptions: { toolName: 'BrushEraser' },
      },
    ],
  },
];

export default {
  definitions,
  defaultContext: 'ACTIVE_VIEWPORT::CORNERSTONE',
};
