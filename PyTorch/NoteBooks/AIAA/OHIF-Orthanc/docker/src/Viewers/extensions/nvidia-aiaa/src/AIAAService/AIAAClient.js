// SPDX-License-Identifier: Apache-2.0

import AIAAUtils from './AIAAUtils';

export default class AIAAClient {
  constructor(server_url) {
    this.server_url = new URL(server_url);
  }

  setServerURL(url) {
    this.server_url = url;
  }

  getServerURL() {
    return this.server_url.toString();
  }

  getModelsURL() {
    let model_url = new URL('v1/models', this.server_url);
    return model_url.toString();
  }

  getLogsURL(lines = 100) {
    let log_url = new URL('logs/', this.server_url);
    log_url.searchParams.append('lines', lines);
    return log_url.toString();
  }

  /**
   * Use either model name or label to query available models in AIAA
   * @param {string} model_name
   * @param {string} label
   */
  async model_list(model_name = undefined, label = undefined) {
    console.info('AIAA fetching models');
    let model_url = new URL('v1/models', this.server_url);
    if (model_name !== undefined)
      model_url.searchParams.append('model', model_name);
    else if (label !== undefined) model_url.searchParams.append('label', label);

    return await AIAAUtils.api_get(model_url.toString());
  }

  /**
   * Calls AIAA create session API
   *
   * @param image_in
   * @param params
   * @param {int} expiry: expiry in seconds.
   *
   * @return {string} session_id
   *
   */
  async createSession(image_in, params, expiry = 0) {
    console.info('AIAAClient - create session');
    let session_url = new URL('session/', this.server_url);
    session_url.searchParams.append('expiry', expiry);
    session_url.searchParams.append('save_as', '.nii');
    return await AIAAUtils.api_put(session_url.toString(), params, image_in);
  }

  /**
   * Get AIAA session API
   *
   * @param session_id
   * @param {boolean} update_ts: session continue
   *
   * @return {string} session_id
   *
   */
  async getSession(session_id, update_ts = false) {
    console.info('AIAAClient - get session');
    let session_url = new URL('session/' + session_id, this.server_url);
    if (update_ts) {
      session_url.searchParams.append('update_ts', update_ts);
    }
    return await AIAAUtils.api_get(session_url.toString());
  }

  async segmentation(model_name, image_in, session_id = undefined, output_type = '.nrrd') {
    const params = {};
    if (output_type) {
      params.result_extension = output_type;
      params.result_dtype = 'uint16';
      params.result_compress = true;
    }

    return this.inference('segmentation', model_name, params, image_in, session_id);
  }

  async deepgrow(model_name, foreground, background, current_point, image_in, session_id = undefined, output_type = '.nrrd') {
    const params = {
      foreground: foreground,
      background: background,
      current_point: current_point,
    };
    if (output_type) {
      params.result_extension = output_type;
      params.result_dtype = 'uint16';
      params.result_compress = true;
    }

    return this.inference('deepgrow', model_name, params, image_in, session_id);
  }

  async dextr3d(model_name, points, image_in, session_id = undefined, output_type = '.nrrd') {
    const params = {
      points: points,
    };
    if (output_type) {
      params.result_extension = output_type;
      params.result_dtype = 'uint16';
      params.result_compress = true;
    }

    return this.inference('dextr3d', model_name, params, image_in, session_id);
  }

  async inference(api, model_name, params, image_in, session_id = undefined) {
    console.info('AIAAClient - calling ' + api);
    let seg_url = new URL('v1/' + api, this.server_url);
    seg_url.searchParams.append('model', model_name);

    // TODO:: parse multi-part
    seg_url.searchParams.append('output', 'image');
    if (session_id !== undefined) {
      seg_url.searchParams.append('session_id', session_id);
    }

    console.info(params);
    return await AIAAUtils.api_post_file(seg_url.toString(), params, image_in);
  }
}
