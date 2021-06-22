// SPDX-License-Identifier: Apache-2.0

import React from 'react';
import PropTypes from 'prop-types';

class CheckBox extends React.Component {
  static propTypes = {
    defaultChecked: PropTypes.bool,
    name: PropTypes.string,
    handleClick: PropTypes.func,
    description: PropTypes.string,
    disabled: PropTypes.bool,
  };

  render() {
    return (
      <tr>
        <td>{this.props.description}:</td>
        <td>
          <input
            name={this.props.name}
            type="checkbox"
            defaultChecked={this.props.defaultChecked}
            onClick={this.props.handleClick}
            disabled={this.props.disabled}
          />
        </td>
      </tr>
    );
  }
}

export default class AIAASettings extends React.Component {
  static propTypes = {
    title: PropTypes.string,
    open: PropTypes.bool,
    settings: PropTypes.any,
    onUpdate: PropTypes.func,
  };

  constructor(props) {
    super(props);
    this.state = {
      open: false,
      settings: props.settings,
    };
  }

  togglePanel = () => {
    this.setState({ open: !this.state.open });
  };

  onChangeFetchFromDICOM = () => {
    let settings = this.props.settings;
    settings.fetch_from_dicom_server = !settings.fetch_from_dicom_server;
    this.props.onUpdate(settings);
  };

  handleClick = evt => {
    let settings = this.props.settings;
    settings[evt.target.name] = !settings[evt.target.name];
    this.props.onUpdate(settings);
  };

  handleSelect = evt => {
    let settings = this.props.settings;
    settings[evt.target.name] = evt.target.value;
    this.props.onUpdate(settings);
  };

  onBlurDICOMAE = evt => {
    let settings = this.props.settings;
    settings.dicom.ae_title = evt.target.value;
    this.props.onUpdate(settings);
  };

  onBlurDICOMURL = evt => {
    let settings = this.props.settings;
    let text = evt.target.value.split(':');
    settings.dicom.server_address = text[0];
    settings.dicom.server_port = parseInt(text[1], 10);
    this.props.onUpdate(settings);
  };

  render() {
    const aiaa_settings = this.props.settings;

    return (
      <div>
        <button
          onClick={e => this.togglePanel(e)}
          className={this.state.open ? 'settings_active' : 'settings_header'}
        >
          {this.props.title}
        </button>
        {this.state.open ? (
          <div className="settings_content">
            <div>
              <table width="100%">
                <tbody className="aiaaTable">
                  <CheckBox
                    name="aiaa_session"
                    description="Use AIAA Session"
                    defaultChecked={true}
                    disabled={true}
                  />
                  <CheckBox
                    name="overlap_segments"
                    description="Overlapping Segments"
                    defaultChecked={aiaa_settings.overlap_segments}
                    handleClick={this.handleClick}
                  />
                  <CheckBox
                    name="dextr3d_auto_run"
                    description="Auto Run DExtr3D"
                    defaultChecked={aiaa_settings.dextr3d_auto_run}
                    handleClick={this.handleClick}
                  />
                  <tr>
                    <td>Export As:</td>
                    <td>
                      <select
                        name="export_format"
                        defaultValue={aiaa_settings.export_format}
                        onChange={this.handleSelect}
                      >
                        <option value="NRRD">NRRD</option>
                        <option value="NIFTI">NIFTI</option>
                        <option value="DICOM-SEG">DICOM-SEG</option>
                      </select>
                    </td>
                  </tr>
                  <CheckBox
                    name="fetch_from_dicom_server"
                    description="Fetch Images From DICOM Server"
                    defaultChecked={aiaa_settings.fetch_from_dicom_server}
                    handleClick={this.handleClick}
                  />
                  <tr
                    style={{
                      filter: aiaa_settings.fetch_from_dicom_server
                        ? 'brightness(1)'
                        : 'brightness(0.5)',
                    }}
                  >
                    <td>DICOM Server:</td>
                    <td>
                      <input
                        className="segEdit"
                        type="text"
                        defaultValue={
                          aiaa_settings.dicom.server_address +
                          ':' +
                          aiaa_settings.dicom.server_port
                        }
                        onBlur={this.onBlurDICOMURL}
                        disabled={!aiaa_settings.fetch_from_dicom_server}
                      />
                    </td>
                  </tr>
                  <tr
                    style={{
                      filter: aiaa_settings.fetch_from_dicom_server
                        ? 'brightness(1)'
                        : 'brightness(0.5)',
                    }}
                  >
                    <td>DICOM AE Title:</td>
                    <td>
                      <input
                        className="segEdit"
                        type="text"
                        defaultValue={aiaa_settings.dicom.ae_title}
                        onBlur={this.onBlurDICOMAE}
                        disabled={!aiaa_settings.fetch_from_dicom_server}
                      />
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        ) : null}
      </div>
    );
  }
}
