// SPDX-License-Identifier: Apache-2.0

import React, { Component } from 'react';
import PropTypes from 'prop-types';
import MD5 from 'md5.js';

import { Icon } from '@ohif/ui';
import { UINotificationService, utils } from '@ohif/core';
import cornerstoneTools from 'cornerstone-tools';
import cornerstone from 'cornerstone-core';

import './AIAAPanel.styl';
import AIAATable from './AIAATable';
import AIAASettings from './AIAASettings';

import { AIAAClient, AIAAUtils, AIAAVolume } from '../AIAAService';
import {
  createSegment,
  deleteSegment,
  flattenLabelmaps,
  getImageIdsForDisplaySet,
  getLabelMaps,
  updateSegment,
  updateSegmentMeta,
} from '../utils/genericUtils';
import AIAASegReader from '../utils/AIAASegReader';

const ColoredCircle = ({ color }) => {
  return (
    <span
      className="segColor"
      style={{ backgroundColor: `rgba(${color.join(',')})` }}
    ></span>
  );
};

ColoredCircle.propTypes = {
  color: PropTypes.array.isRequired,
};

const DICOM_SERVER_INFO = {
  server_address: '127.0.0.1',
  server_port: 11112,
  ae_title: 'DCM4CHEE',
  query_level: 'PATIENT',
  patient_id: 'unknown (not provided)',
  study_uid: null,
  series_uid: null,
};

export default class AIAAPanel extends Component {
  static propTypes = {
    studies: PropTypes.any,
    viewports: PropTypes.any,
    activeIndex: PropTypes.any,
  };

  static defaultProps = {
    studies: undefined,
    viewports: undefined,
    activeIndex: undefined,
  };

  constructor(props) {
    super(props);
    this.notification = UINotificationService.create({});

    console.debug(props);
    const { viewports, studies, activeIndex } = props;

    this.viewConstants = this.getViewConstants(viewports, studies, activeIndex);
    const aiaaSettings = this.getAIAASettings();
    const labelmaps = getLabelMaps(this.viewConstants.element);
    const segments = flattenLabelmaps(labelmaps);

    this.state = {
      aiaaSettings: aiaaSettings,
      segments: segments,
      selectedSegmentId: segments && segments.length ? segments[0].id : null,
      //
      segModels: [],
      annModels: [],
      deepgrowModels: [],
      currentSegModel: null,
      currentAnnModel: null,
      currentDeepgrowModel: null,
      extremePoints: new Map(),
      deepgrowPoints: new Map(),
      //
      currentEvent: null,
      aiaaOpInProgress: false,
      imageHeader: null,
    };
  }

  async componentDidMount() {
    await this.onClickModels();
  }

  getAIAASettings = () => {
    const url = AIAAUtils.getAIAACookie('NVIDIA_AIAA_SERVER_URL', 'http://127.0.0.1:3030/aiaa/');
    const overlap_segments = AIAAUtils.getAIAACookieBool('NVIDIA_AIAA_OVERLAP_SEGMENTS', false);
    const export_format = AIAAUtils.getAIAACookie('NVIDIA_AIAA_EXPORT_FORMAT', 'DICOM-SEG');
    const dextr3d_min_points = AIAAUtils.getAIAACookieNumber('NVIDIA_AIAA_DEXTR3D_MIN_POINTS', 6);
    const dextr3d_auto_run = AIAAUtils.getAIAACookieBool('NVIDIA_AIAA_DEXTR3D_AUTO_RUN', true);
    const fetch_from_dicom_server = AIAAUtils.getAIAACookieBool('NVIDIA_AIAA_FETCH_FROM_DICOM_SERVER', true);
    const server_address = AIAAUtils.getAIAACookie('NVIDIA_AIAA_DICOM_SERVER_ADDRESS', 'orthanc');
    const server_port = AIAAUtils.getAIAACookieNumber('NVIDIA_AIAA_DICOM_SERVER_PORT', 4242);
    const ae_title = AIAAUtils.getAIAACookie('NVIDIA_AIAA_DICOM_AE_TITLE', 'ORTHANC');

    return {
      url: url,
      overlap_segments: overlap_segments,
      export_format: export_format,
      dextr3d_min_points: dextr3d_min_points,
      dextr3d_auto_run: dextr3d_auto_run,
      fetch_from_dicom_server: fetch_from_dicom_server,
      dicom: {
        server_address: server_address,
        server_port: server_port,
        ae_title: ae_title,
      },
    };
  };

  updateAIAASettings = (aiaaSettings) => {
    console.info(aiaaSettings);
    AIAAUtils.setAIAACookie('NVIDIA_AIAA_SERVER_URL', aiaaSettings.url);
    AIAAUtils.setAIAACookie('NVIDIA_AIAA_OVERLAP_SEGMENTS', aiaaSettings.overlap_segments);
    AIAAUtils.setAIAACookie('NVIDIA_AIAA_EXPORT_FORMAT', aiaaSettings.export_format);
    AIAAUtils.setAIAACookie('NVIDIA_AIAA_DEXTR3D_MIN_POINTS', aiaaSettings.dextr3d_min_points);
    AIAAUtils.setAIAACookie('NVIDIA_AIAA_DEXTR3D_AUTO_RUN', aiaaSettings.dextr3d_auto_run);
    AIAAUtils.setAIAACookie('NVIDIA_AIAA_FETCH_FROM_DICOM_SERVER', aiaaSettings.fetch_from_dicom_server);
    AIAAUtils.setAIAACookie('NVIDIA_AIAA_DICOM_SERVER_ADDRESS', aiaaSettings.dicom.server_address);
    AIAAUtils.setAIAACookie('NVIDIA_AIAA_DICOM_SERVER_PORT', aiaaSettings.dicom.server_port);
    AIAAUtils.setAIAACookie('NVIDIA_AIAA_DICOM_AE_TITLE', aiaaSettings.dicom.ae_title);

    this.setState({ aiaaSettings });
  };

  getViewConstants = (viewports, studies, activeIndex) => {
    const viewport = viewports[activeIndex];
    const { PatientID } = studies[activeIndex];

    const {
      StudyInstanceUID,
      SeriesInstanceUID,
      displaySetInstanceUID,
    } = viewport;

    const studyMetadata = utils.studyMetadataManager.get(StudyInstanceUID);
    const firstImageId = studyMetadata.getFirstImageId(displaySetInstanceUID);

    const imageIds = getImageIdsForDisplaySet(studies, StudyInstanceUID, SeriesInstanceUID);
    const imageIdsToIndex = new Map();
    for (let i = 0; i < imageIds.length; i++) {
      imageIdsToIndex.set(imageIds[i], i);
    }

    const element = cornerstone.getEnabledElements()[this.props.activeIndex].element;
    const cookiePostfix = new MD5().update(PatientID + StudyInstanceUID + SeriesInstanceUID).digest('hex');

    return {
      PatientID: PatientID,
      StudyInstanceUID: StudyInstanceUID,
      SeriesInstanceUID: SeriesInstanceUID,
      displaySetInstanceUID: displaySetInstanceUID,
      firstImageId: firstImageId,
      imageIdsToIndex: imageIdsToIndex,
      element: element,
      numberOfFrames: imageIds.length,
      cookiePostfix: cookiePostfix,
    };
  };

  onBlurSeverURL = evt => {
    let value = evt.target.value;
    const aiaaSettings = Object.assign({}, this.state.aiaaSettings, { url: value });

    this.setState({ aiaaSettings: aiaaSettings });
    AIAAUtils.setAIAACookie('NVIDIA_AIAA_SERVER_URL', value);
  };

  setModels = response => {
    let segModels = [];
    let annModels = [];
    let deepgrowModels = [];

    for (let i = 0; i < response.data.length; ++i) {
      if (response.data[i].type === 'annotation') {
        annModels.push(response.data[i]);
      } else if (response.data[i].type === 'segmentation') {
        segModels.push(response.data[i]);
      } else if (response.data[i].type === 'deepgrow') {
        deepgrowModels.push(response.data[i]);
      } else if (response.data[i].type === 'pipeline') {
        segModels.push(response.data[i]);
        deepgrowModels.push(response.data[i]);
      } else {
        console.warn(response.data[i].name + ' has unsupported types for this plugin');
      }
    }

    const currentSegModel = segModels.length > 0 ? segModels[0] : null;
    const currentAnnModel = annModels.length > 0 ? annModels[0] : null;
    const currentDeepgrowModel = deepgrowModels.length > 0 ? deepgrowModels[0] : null;

    this.setState({
      segModels: segModels,
      annModels: annModels,
      deepgrowModels: deepgrowModels,
      currentSegModel: currentSegModel,
      currentAnnModel: currentAnnModel,
      currentDeepgrowModel: currentDeepgrowModel,
    });
  };

  onClickModels = async () => {
    let aiaaClient = new AIAAClient(this.state.aiaaSettings.url);
    let response = await aiaaClient.model_list();
    if (response.status !== 200) {
      this.notification.show({
        title: 'NVIDIA AIAA',
        message: 'Failed to fetch AIAA models...\nReason: ' + response.data,
        type: 'error',
        duration: 5000,
      });
      return;
    }
    this.setModels(response);

    this.notification.show({
      title: 'NVIDIA AIAA',
      message: 'Fetched AIAA models complete!',
      type: 'success',
      duration: 2000,
    });
  };

  onCreateOrGetAiaaSession = async () => {
    const { studies } = this.props;
    const { PatientID, StudyInstanceUID, SeriesInstanceUID } = this.viewConstants;

    const cookieId = 'NVIDIA_AIAA_SESSION_ID_' + this.viewConstants.cookiePostfix;
    let aiaaClient = new AIAAClient(this.state.aiaaSettings.url);

    let c_session_id = AIAAUtils.getAIAACookie(cookieId);
    if (c_session_id) {
      const response = await aiaaClient.getSession(c_session_id);
      if (response.status === 200) {
        return c_session_id;
      }
    }

    this.notification.show({
      title: 'NVIDIA AIAA',
      message: 'Please wait while creating new AIAA Session!',
      type: 'info',
      duration: 10000,
    });

    let response;
    if (this.state.aiaaSettings.fetch_from_dicom_server) {
      DICOM_SERVER_INFO.server_address = this.state.aiaaSettings.dicom.server_address;
      DICOM_SERVER_INFO.server_port = this.state.aiaaSettings.dicom.server_port;
      DICOM_SERVER_INFO.ae_title = this.state.aiaaSettings.dicom.ae_title;
      DICOM_SERVER_INFO.patient_id = PatientID;
      DICOM_SERVER_INFO.series_uid = SeriesInstanceUID;
      DICOM_SERVER_INFO.study_uid = StudyInstanceUID;
      DICOM_SERVER_INFO.query_level = 'SERIES';

      response = await aiaaClient.createSession(null, {'dicom': DICOM_SERVER_INFO});
    } else {
      const useNifti = false;
      let volumes;
      if (useNifti) {
        // TODO:: Current NIFTI data when we load in MITK (from aiaa session) it's blurr
        //        Is our NIFTI Data creation Robust? We need to verify it (otherwise, have settings to use nifti/dicom)
        //        Otherwise this can be fast (as all image slices are locally loaded by cornerstone and cached)
        volumes = await new AIAAVolume().createNiftiData();
      } else {
        volumes = await new AIAAVolume().createDicomData(
          studies,
          StudyInstanceUID,
          SeriesInstanceUID,
        );
      }

      this.notification.show({
        title: 'NVIDIA AIAA',
        message: 'AIAA Data preparation complete!',
        type: 'success',
      });
      response = await aiaaClient.createSession(volumes, null);
    }

    if (response.status !== 200) {
      this.notification.show({
        title: 'NVIDIA AIAA',
        message: 'Failed to Create AIAA Session...\nReason: ' + response.data,
        type: 'error',
        duration: 5000,
      });
      return null;
    }

    this.notification.show({
      title: 'NVIDIA AIAA',
      message: 'AIAA Session create success!',
      type: 'success',
    });

    const { session_id } = response.data;
    console.info('AIAA Session created: ' + session_id);
    AIAAUtils.setAIAACookie(cookieId, session_id);
    return session_id;
  };

  onSelectSegModel = name => {
    const currentSegModel = this.state.segModels.find(x => x.name === name);
    this.setState({ currentSegModel });
  };

  onSelectAnnModel = name => {
    const currentAnnModel = this.state.annModels.find(x => x.name === name);
    this.setState({ currentAnnModel });
  };

  onSelectDeepgrowModel = name => {
    const currentDeepgrowModel = this.state.deepgrowModels.find(x => x.name === name);
    this.setState({ currentDeepgrowModel });
  };

  getSelectedActiveIndex = () => {
    // const obj = document.querySelector('input[name="segitem"]:checked');
    const id = this.state.selectedSegmentId;
    console.debug('Getting selected index ' + id);
    if (id) {
      let index = id.split('+').map(Number);
      return { id, labelmapIndex: index[0], segmentIndex: index[1] };
    }
    return null;
  };

  onClickSegBtn = async () => {
    // TODO:: Disable Everything like Segmentation/Dextra/Deepgrow/OnSelectSegmentation
    //        Or use callback to update the correct LabelMapIndex/SegmentIndex (2nd preferred)
    const model_name = this.state.currentSegModel ? this.state.currentSegModel.name : null;
    if (!model_name) {
      this.notification.show({
        title: 'NVIDIA AIAA',
        message: 'Model is NOT selected',
        type: 'info',
      });
      throw Error('Model is not selected');
    }
    const labels = this.state.currentSegModel.labels;

    let aiaaClient = new AIAAClient(this.state.aiaaSettings.url);
    const session_id = await this.onCreateOrGetAiaaSession();
    if (!session_id) {
      return;
    }

    this.notification.show({
      title: 'NVIDIA AIAA',
      message: 'Running AIAA Auto-Segmentation...',
      type: 'info',
      duration: 10000,
    });

    this.setState({ aiaaOpInProgress: true });
    let response = await aiaaClient.segmentation(
      model_name,
      null,
      session_id,
    );
    this.setState({ aiaaOpInProgress: false });

    if (response.status !== 200) {
      this.notification.show({
        title: 'NVIDIA AIAA',
        message: 'Failed to Run Auto-Segmentation...\nReason: ' + response.data,
        type: 'error',
        duration: 5000,
      });
      return;
    }

    await this.updateView(null, response, labels);

    this.notification.show({
      title: 'NVIDIA AIAA',
      message: 'AIAA Auto-Segmentation complete!',
      type: 'success',
    });
  };

  onClickDExtr3DBtn = async () => {
    const model_name = this.state.currentAnnModel ? this.state.currentAnnModel.name : null;
    if (!model_name) {
      this.notification.show({
        title: 'NVIDIA AIAA',
        message: 'Model is NOT selected',
        type: 'warning',
      });
      throw Error('Model is not selected');
    }

    const activeIndex = this.getSelectedActiveIndex();
    const points = this.state.extremePoints.get(activeIndex.id);
    const pts = points.map(p => [p.x, p.y, p.z]);
    if (pts.length < 6) {
      this.notification.show({
        title: 'NVIDIA AIAA',
        message: 'Min 6 Extreme Points required',
        type: 'warning',
      });
      return;
    }

    let aiaaClient = new AIAAClient(this.state.aiaaSettings.url);
    const session_id = await this.onCreateOrGetAiaaSession();
    if (!session_id) {
      return;
    }

    this.notification.show({
      title: 'NVIDIA AIAA',
      message: 'Running AIAA DExtr3D...',
      type: 'info',
      duration: 2000,
    });

    this.setState({ aiaaOpInProgress: true });
    let response = await aiaaClient.dextr3d(
      model_name,
      pts,
      null,
      session_id,
    );
    this.setState({ aiaaOpInProgress: false });

    if (response.status !== 200) {
      this.notification.show({
        title: 'NVIDIA AIAA',
        message: 'Failed to Run DExtr3D...\nReason: ' + response.data,
        type: 'error',
        duration: 5000,
      });
      return;
    }

    await this.updateView(activeIndex, response, null);
  };

  onDeepgrow = async (currentPoint) => {
    const model_name = this.state.currentDeepgrowModel ? this.state.currentDeepgrowModel.name : null;
    const deepgrow_type = this.state.currentDeepgrowModel ? this.state.currentDeepgrowModel.deepgrow : null;
    const is3D = deepgrow_type && (deepgrow_type === '3d' || deepgrow_type === '3D');
    console.debug('Deepgrow 3D: ' + is3D);

    if (!model_name) {
      this.notification.show({
        title: 'NVIDIA AIAA',
        message: 'Model is NOT selected',
        type: 'info',
      });
      throw Error('Model is not selected');
    }

    let aiaaClient = new AIAAClient(this.state.aiaaSettings.url);
    const session_id = await this.onCreateOrGetAiaaSession();
    if (!session_id) {
      return;
    }

    this.notification.show({
      title: 'NVIDIA AIAA',
      message: 'Running AIAA Deepgrow...',
      type: 'info',
      duration: 2000,
    });

    const activeIndex = this.getSelectedActiveIndex();
    const points = this.state.deepgrowPoints.get(activeIndex.id);
    const fg = points.filter(p => (is3D || p.z === currentPoint.z) && !p.data.ctrlKey).map(p => [p.x, p.y, p.z]);
    const bg = points.filter(p => (is3D || p.z === currentPoint.z) && p.data.ctrlKey).map(p => [p.x, p.y, p.z]);
    const cp = [[currentPoint.x, currentPoint.y, currentPoint.z]];

    this.setState({ aiaaOpInProgress: true });
    let response = await aiaaClient.deepgrow(
      model_name,
      fg,
      bg,
      cp,
      null,
      session_id,
    );
    this.setState({ aiaaOpInProgress: false });

    if (response.status !== 200) {
      this.notification.show({
        title: 'NVIDIA AIAA',
        message: 'Failed to Run Deepgrow...\nReason: ' + response.data,
        type: 'error',
        duration: 5000,
      });
      return;
    }

    await this.updateView(activeIndex, response, null, 'override', is3D ? -1 : currentPoint.z);
  };

  /**
   * Updates cornerstone view given response getting from AIAA
   *
   * @param {Object} response
   * @param {Array} [labels] An array of label names
   */
  updateView = async (activeIndex, response, labels, operation, slice) => {
    const { element, numberOfFrames } = this.viewConstants;
    const { header, image } = AIAASegReader.parseNrrdData(response.data);
    const overlap_segments = this.state.aiaaSettings.overlap_segments;

    if (labels) {
      for (let i = 0; i < labels.length; i++) {
        const resp = createSegment(element, labels[i], i === 0 ? (!overlap_segments) : false);
        if (i === 0) {
          activeIndex = resp;
        }

        if (this.state.selectedSegmentId) {
          this.refreshSegTable();
        } else {
          this.refreshSegTable(activeIndex.id);
        }
      }
    }

    if (!operation && overlap_segments) {
      operation = 'overlap';
    }

    if (!this.state.imageHeader) {
      this.setState({ imageHeader: header });
    }
    updateSegment(element, activeIndex.labelmapIndex, activeIndex.segmentIndex, image, numberOfFrames, operation, slice);
  };

  onClickAddSegment = () => {
    const { element } = this.viewConstants;
    const { id } = createSegment(element, undefined, !this.state.aiaaSettings.overlap_segments);
    this.refreshSegTable(id);
  };

  onSelectSegment = evt => {
    let id = evt.currentTarget.value;
    this.setState({ selectedSegmentId: id });
  };

  onUpdateLabelOrDesc = (id, evt, label) => {
    const { element } = this.viewConstants;
    let index = id.split('+').map(Number);
    const labelmapIndex = index[0];
    const segmentIndex = index[1];

    if (label) {
      updateSegmentMeta(element, labelmapIndex, segmentIndex, evt.currentTarget.textContent, undefined)
    } else {
      updateSegmentMeta(element, labelmapIndex, segmentIndex, undefined, evt.currentTarget.textContent)
    }
  };

  onClickDeleteSegment = () => {
    const activeIndex = this.getSelectedActiveIndex();
    const { element } = this.viewConstants;

    deleteSegment(element, activeIndex.labelmapIndex, activeIndex.segmentIndex);
    this.clearPointsAll(activeIndex);
    this.refreshSegTable(null);
  };

  refreshSegTable = (id) => {
    const labelmaps = getLabelMaps(this.viewConstants.element);
    const segments = flattenLabelmaps(labelmaps);
    if (id === undefined) {
      this.setState({ segments: segments });
    } else {
      this.setState({ segments: segments, selectedSegmentId: id });
    }
  };

  onSelectActionTab = evt => {
    let selected = evt.currentTarget.value;
    if (selected === 'dextr3d') {
      cornerstoneTools.setToolDisabled('DeepgrowProbe', {});
      cornerstoneTools.setToolActive('DExtr3DProbe', { mouseButtonMask: 1 });

      this.addEventListeners('nvidia_aiaa_event_DExtr3DProbe', this.dextr3DClickEventHandler);
    } else if (selected === 'deepgrow') {
      cornerstoneTools.setToolDisabled('DExtr3DProbe', {});
      cornerstoneTools.setToolActive('DeepgrowProbe', { mouseButtonMask: 1 });

      // cornerstonetoolsmeasurementadded (also can be handled; better to be specific)
      this.addEventListeners('nvidia_aiaa_event_DeepgrowProbe', this.deepgrowClickEventHandler);
    } else {
      cornerstoneTools.setToolDisabled('DExtr3DProbe', {});
      cornerstoneTools.setToolDisabled('DeepgrowProbe', {});

      this.removeEventListeners();
    }
  };

  addEventListeners = (eventName, handler) => {
    this.removeEventListeners();

    const { element } = this.viewConstants;
    element.addEventListener(eventName, handler);
    this.setState({ currentEvent: { name: eventName, handler: handler } });
  };

  removeEventListeners = () => {
    if (!this.state.currentEvent) {
      return;
    }

    const { element } = this.viewConstants;
    const { currentEvent } = this.state;

    element.removeEventListener(currentEvent.name, currentEvent.handler);
    this.setState({ currentEvent: null });
  };

  onClickExportSegments = async () => {
    const { getters } = cornerstoneTools.getModule('segmentation');
    const { labelmaps3D } = getters.labelmaps3D(this.viewConstants.element);
    if (!labelmaps3D) {
      console.info('LabelMap3D is empty.. so zero segments');
      return;
    }

    if (this.state.aiaaSettings.export_format === 'DICOM-SEG') {
      //AEH comment confirm question
      // if (!confirm('This will add a new version of DICOM-SEG into server.  Do you want to continue?')) {
      //   return;
      // }

      const {studies} = this.props;
      const {StudyInstanceUID, SeriesInstanceUID} = this.viewConstants;

      this.notification.show({
        title: 'NVIDIA AIAA',
        message: 'Preparing DICOM-SEG for uploading',
        type: 'info',
        duration: 15000,
      });

      const images = await new AIAAVolume().createDicomData(
          studies,
          StudyInstanceUID,
          SeriesInstanceUID,
          true,
      )

      this.notification.show({
        title: 'NVIDIA AIAA',
        message: 'DICOM-SEG Preparation Completed, now uploading',
        type: 'info',
        duration: 5000,
      });

      AIAASegReader.serializeDicomSeg(images, labelmaps3D, 'segment.dcm');

      this.notification.show({
        title: 'NVIDIA AIAA',
        message: 'DICOM-SEG for uploaded/saved',
        type: 'success',
        duration: 10000,
      });
      return;
    }

    for (let i = 0; i < labelmaps3D.length; i++) {
      const labelmap3D = labelmaps3D[i];
      if (!labelmap3D) {
        console.warn('Missing Label; so ignore');
        continue;
      }

      const metadata = labelmap3D.metadata.data ? labelmap3D.metadata.data : labelmap3D.metadata;
      if (!metadata || !metadata.length) {
        console.warn('Missing Meta; so ignore');
        continue;
      }

      console.info(this.state.aiaaSettings.export_format + ' - Saving LabelMap: ' + i);
      if (this.state.aiaaSettings.export_format === 'NIFTI') {
        AIAASegReader.serializeNrrdToNii(this.state.imageHeader, labelmap3D.buffer, 'segment-' + i + '.nii.gz');
      } else {
        AIAASegReader.serializeNrrdCompressed(this.state.imageHeader, labelmap3D.buffer, 'segment-' + i + '.nrrd');
      }
    }
  };

  initPointsAll = () => {
    const activeIndex = this.getSelectedActiveIndex();
    if (activeIndex) {
      this.initPoints('DExtr3DProbe', activeIndex);
      this.initPoints('DeepgrowProbe', activeIndex);
    }
  };

  initPoints = (toolName, activeIndex) => {
    const { setters } = cornerstoneTools.getModule('segmentation');
    const { element } = this.viewConstants;
    const { id, labelmapIndex, segmentIndex } = activeIndex;

    setters.activeLabelmapIndex(element, labelmapIndex);
    setters.activeSegmentIndex(element, segmentIndex);
    cornerstoneTools.clearToolState(element, toolName);

    // Add Points
    // TODO:: Currently all points are becoming visible on same Frame
    const pointsAll = (toolName === 'DExtr3DProbe') ? this.state.extremePoints : this.state.deepgrowPoints;
    const points = pointsAll.get(id);
    if (points) {
      for (let i = 0; i < points.length; i++) {
        const enabledElement = cornerstone.getEnabledElement(element);
        const oldImageId = enabledElement.image.imageId;

        for (let i = 0; i < points.length; ++i) {
          // add tool state will only add on that image (2D)
          let { imageId, data } = points[i];
          enabledElement.image.imageId = imageId;
          cornerstoneTools.addToolState(element, toolName, data);
        }
        enabledElement.image.imageId = oldImageId;
        cornerstone.updateImage(element);
      }
    }

    // Refresh
    cornerstone.updateImage(element);
  };

  clearPointsAll = (activeIndex) => {
    this.clearPoints('DExtr3DProbe', activeIndex);
    this.clearPoints('DeepgrowProbe', activeIndex);
  };

  clearPoints = (toolName, activeIndex) => {
    const pointsAll = (toolName === 'DExtr3DProbe') ? this.state.extremePoints : this.state.deepgrowPoints;

    activeIndex = activeIndex ? activeIndex : this.getSelectedActiveIndex();
    const points = pointsAll.get(activeIndex.id);
    if (points) {
      const { element } = this.viewConstants;
      const enabledElement = cornerstone.getEnabledElement(element);
      const oldImageId = enabledElement.image.imageId;

      for (let i = 0; i < points.length; ++i) {
        // clear tool state will only clear on that image (2D)
        let { imageId } = points[i];
        enabledElement.image.imageId = imageId;
        cornerstoneTools.clearToolState(element, toolName);
      }
      enabledElement.image.imageId = oldImageId;
      cornerstone.updateImage(element);
      pointsAll.delete(activeIndex.id);
    }
  };

  getPointData = (evt) => {
    const { x, y, imageId } = evt.detail;
    const z = this.viewConstants.imageIdsToIndex.get(imageId);

    console.debug('X: ' + x + '; Y: ' + y + '; Z: ' + z);
    return { x, y, z, data: evt.detail, imageId };
  };

  dextr3DClickEventHandler = async (evt) => {
    if (!evt || !evt.detail) {
      console.info('dextr3DClickEventHandler:: Not a valid event; So Ignore');
      return;
    }

    const activeIndex = this.state.selectedSegmentId;
    if (!activeIndex) {
      this.notification.show({
        title: 'NVIDIA AIAA',
        message: 'Please create/select a label first',
        type: 'warning',
      });
      return;
    }

    let points = this.state.extremePoints.get(activeIndex);
    if (!points) {
      points = [];
      this.state.extremePoints.set(activeIndex, points);
    }

    points.push(this.getPointData(evt));
    const { dextr3d_min_points, dextr3d_auto_run } = this.state.aiaaSettings;

    if (points.length === 1) {
      this.notification.show({
        title: 'NVIDIA AIAA',
        message: 'Continue adding more extreme points (Min Required: ' + dextr3d_min_points + ')',
        type: 'info',
      });
    }

    if (dextr3d_auto_run && points.length >= dextr3d_min_points) {
      await this.onClickDExtr3DBtn();
    }
  };

  deepgrowClickEventHandler = async (evt) => {
    if (!evt || !evt.detail) {
      console.info('deepgrowClickEventHandler:: Not a valid event; So Ignore');
      return;
    }

    const activeIndex = this.state.selectedSegmentId;
    if (!activeIndex) {
      this.notification.show({
        title: 'NVIDIA AIAA',
        message: 'Please create/select a label first',
        type: 'warning',
      });
      return;
    }

    let points = this.state.deepgrowPoints.get(activeIndex);
    if (!points) {
      points = [];
      this.state.deepgrowPoints.set(activeIndex, points);
    }

    const pointData = this.getPointData(evt);
    points.push(pointData);

    await this.onDeepgrow({x: pointData.x, y: pointData.y, z: pointData.z});
  };

  componentDidUpdate(prevProps, prevState, snapshot) {
    if (prevState.selectedSegmentId !== this.state.selectedSegmentId) {
      if (this.state.selectedSegmentId) {
        this.initPointsAll();
      }
    }
  }

  render() {
    // const segments = [].concat.apply([], this.state.segments);
    const totalSegments = this.state.segments.length;

    return (
      <div className="aiaaPanel">
        <table>
          <tbody>
          <tr>
            <td className="aiaaTitle">NVIDIA Clara AIAA</td>
          </tr>
          <tr>
            <td className="aiaaSubtitle">All Segments: <b>{totalSegments}</b></td>
          </tr>
          <tr>
            <td>
              <button
                className="segButton"
                onClick={this.onClickAddSegment}
                title="Add Segment"
              >
                <Icon name="plus" width="12px" height="12px"/>
                Add
              </button>
              &nbsp;
              <button
                className="segButton"
                onClick={this.onClickDeleteSegment}
                id="segDeleteBtn"
                title="Delete Selected Segment"
                disabled={!this.state.selectedSegmentId}
              >
                <Icon name="trash" width="12px" height="12px"/>
                Remove
              </button>
            </td>
            <td align="right">
              <button
                className="segButton"
                onClick={this.onClickExportSegments}
                title={'Save/Download Segments'}
                disabled={!((this.state.imageHeader || this.state.aiaaSettings.export_format === 'DICOM-SEG') && totalSegments)}
              >
                <Icon name="save" width="12px" height="12px"/>
                &nbsp;{(this.state.aiaaSettings.export_format === 'DICOM-SEG')? 'Save' : 'Download'}
              </button>
            </td>
          </tr>
          </tbody>
        </table>

        <div className="segSection">
          <table className="segTable">
            <thead>
            <tr>
              <th width="2%">#</th>
              <th width="8%">Color</th>
              <th width="60%">Name</th>
              <th width="30%">Desc</th>
            </tr>
            </thead>
            <tbody>
            {this.state.segments.map(seg => (
              <tr key={seg.id}>
                <td>
                  <input
                    type="radio"
                    name="segitem"
                    value={seg.id}
                    checked={seg.id === this.state.selectedSegmentId}
                    onChange={this.onSelectSegment}
                  />
                </td>
                <td>
                  <ColoredCircle color={seg.color}/>
                </td>
                <td className="segEdit" contentEditable="true" suppressContentEditableWarning="true"
                    onKeyUp={(evt) => this.onUpdateLabelOrDesc(seg.id, evt, true)}>
                  {seg.meta.SegmentLabel}
                </td>
                <td contentEditable="true" suppressContentEditableWarning="true"
                    onKeyUp={(evt) => this.onUpdateLabelOrDesc(seg.id, evt, false)}>
                  {seg.meta.SegmentDescription}
                </td>
              </tr>
            ))}
            </tbody>
          </table>
        </div>

        <br/>
        <table className="aiaaTable">
          <tbody>
          <tr>
            <td colSpan="3">AIAA server URL:</td>
          </tr>
          <tr>
            <td width="80%">
              <input
                className="aiaaInput"
                name="aiaaServerURL"
                type="text"
                defaultValue={this.state.aiaaSettings.url}
                onBlur={this.onBlurSeverURL}
              />
            </td>
            <td width="2%">&nbsp;</td>
            <td width="18%">
              <button className="aiaaButton" onClick={this.onClickModels}>
                <Icon name="reset" width="16px" height="16px"/>
              </button>
            </td>
          </tr>
          <tr>
            <td colSpan="3">
              <a href={new URL(this.state.aiaaSettings.url).toString() + 'v1/models'} target="_blank"
                 rel="noopener noreferrer">
                All models
              </a>
              <b>&nbsp;&nbsp;|&nbsp;&nbsp;</b>
              <a href={new URL(this.state.aiaaSettings.url).toString() + 'logs/?lines=100'} target="_blank"
                 rel="noopener noreferrer">
                AIAA Logs
              </a>
            </td>
          </tr>
          </tbody>
        </table>

        <AIAASettings
          title="More AIAA Settings..."
          settings={this.state.aiaaSettings}
          onUpdate={this.updateAIAASettings}
        >
        </AIAASettings>

        <div className="tabs">
          <div className="tab">
            <input
              type="radio"
              name="css-tabs"
              id="tab-1"
              className="tab-switch"
              value="segmentation"
              onClick={this.onSelectActionTab}
              defaultChecked
            />
            <label htmlFor="tab-1" className="tab-label">Segmentation</label>

            <div className="tab-content">
              <AIAATable
                name="segmentation"
                title="Segmentation"
                models={this.state.segModels}
                currentModel={this.state.currentSegModel}
                onClick={this.onClickSegBtn}
                onSelect={this.onSelectSegModel}
                usage={
                  <p>
                    Fully automated segmentation <b>without any user input</b>.
                    Just select any <i>segmentation</i> model and click to run
                  </p>
                }
              />
            </div>
          </div>

          <div className="tab">
            <input
              type="radio"
              name="css-tabs"
              id="tab-2"
              className="tab-switch"
              value="dextr3d"
              onClick={this.onSelectActionTab}
            />
            <label htmlFor="tab-2" className="tab-label">DExtr3D</label>

            <div className="tab-content">
              <AIAATable
                name="dextr3d"
                title="Annotation (DExtr3D)"
                models={this.state.annModels}
                currentModel={this.state.currentAnnModel}
                onClick={this.onClickDExtr3DBtn}
                onSelect={this.onSelectAnnModel}
                usage={
                  <div>
                    <p>
                      Generally <b>more accurate</b> but requires user provide <i>extreme points</i> of the organ.
                    </p>
                    <a href="#" onClick={() => this.clearPoints('DExtr3DProbe')}>Clear Points</a>
                  </div>
                }
              />
            </div>
          </div>

          <div className="tab">
            <input
              type="radio"
              name="css-tabs"
              id="tab-3"
              className="tab-switch"
              value="deepgrow"
              onClick={this.onSelectActionTab}
            />
            <label htmlFor="tab-3" className="tab-label">DeepGrow</label>

            <div className="tab-content">
              <AIAATable
                name="deepgrow"
                title="DeepGrow"
                models={this.state.deepgrowModels}
                currentModel={this.state.currentDeepgrowModel}
                onSelect={this.onSelectDeepgrowModel}
                usage={
                  <div>
                    <p>
                      You can use DeepGrow model to annotate <b>any organ</b>. &nbsp;Use <i>Ctrl + Click</i> to
                      add <b><i>background</i></b> points.
                    </p>
                    <a href="#" onClick={() => this.clearPoints('DeepgrowProbe')}>Clear Points</a>
                  </div>
                }
              />
            </div>
          </div>
        </div>
      </div>
    );
  }
}
