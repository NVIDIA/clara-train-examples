// SPDX-License-Identifier: Apache-2.0

import React, { Component } from 'react';
import PropTypes from 'prop-types';
import nvidiaLogo from '../icons/nvidia.svg';

import './AIAAPanel.styl';

export default class AIAATable extends Component {
  static propTypes = {
    name: PropTypes.string,
    title: PropTypes.string,
    onClick: PropTypes.func,
    onSelect: PropTypes.func,
    models: PropTypes.array,
    currentModel: PropTypes.any,
    usage: PropTypes.any,
  };

  constructor(props) {
    super(props);

    this.state = {
      isButtonDisabled: false,
    };
  }

  onChangeModel = evt => {
    console.info('Current Selected Model: ' + evt.target.value);
    this.props.onSelect(evt.target.value);
  };

  onClickBtn = async () => {
    if (this.state.isButtonDisabled) {
      return;
    }
    this.setState({ isButtonDisabled: true });
    await this.props.onClick();
    this.setState({ isButtonDisabled: false });
  };

  render() {
    return (
      <div>
        <table className="aiaaTable">
          <tbody>
          <tr>
            <td colSpan="3">{this.props.title} Models:</td>
          </tr>
          <tr>
            <td width="80%">
              <select
                className="aiaaDropDown"
                name={this.props.name + 'Select'}
                onChange={this.onChangeModel}
                value={this.props.currentModel ? this.props.currentModel.name : ''}
              >
                {this.props.models.map(model => (
                  <option
                    key={model.name}
                    value={model.name}
                    aiaalabel={model.labels}
                  >
                    {`${model.name} `}
                  </option>
                ))}
              </select>
            </td>
            <td width="2%">&nbsp;</td>
            <td width="18%">
              <button
                className="aiaaActionButton"
                name={this.props.name + 'Button'}
                onClick={this.onClickBtn}
                title={"Run " + this.props.title}
                disabled={this.state.isButtonDisabled}
                style={{display: (this.props.onClick ? 'block' : 'none')}}
              >
                {React.createElement(nvidiaLogo, { width: '16px', height: '16px' })}
              </button>
            </td>
          </tr>
          </tbody>
        </table>
        {this.props.usage}
      </div>
    );
  }
}
