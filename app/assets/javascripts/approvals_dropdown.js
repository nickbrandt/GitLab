/* global Flash */

import DropLab from './droplab/drop_lab';
import AjaxFilter from './droplab/plugins/ajax_filter';
import InputSetter from './droplab/plugins/input_setter';

class ApprovalsDropdown {
  constructor(trigger, list, usersInput, groupsInput, tokenContainer, inputToken) {
    this.trigger = trigger;
    this.list = list;
    this.usersInput = usersInput;
    this.groupsInput = groupsInput;
    this.tokenContainer = tokenContainer;
    this.inputToken = inputToken;

    this.createConfig();
    this.droplab = new DropLab();
  }

  createConfig() {
    const triggerData = this.trigger.dataset;

    this.config = {
      AjaxFilter: {
        endpoint: triggerData.endpoint,
        searchKey: 'search',
        params: {
          per_page: 20,
          active: true,
          all_available: true,
          // skip_users: triggerData.skipUsers,
          // skip_groups: triggerData.skipGroups,
          // email_user: triggerData.emailUser,
        },
        // loadingTemplate: '<i class="fa fa-spinner fa-spin"></i>',
        onError: ApprovalsDropdown.requestError,
      },
      InputSetter: [{
        input: this.createToken.bind(this),
        setValue: ApprovalsDropdown.setToken,
        valueAttribute: 'data-name',
      }, {
        input: this.getInput.bind(this),
        setValue: ApprovalsDropdown.setInput,
        valueAttribute: 'data-id',
      }],
    };
  }

  initDropLab() {
    this.droplab.init(this.trigger, this.list, [AjaxFilter, InputSetter], this.config);
  }

  getInput(selectedItem) {
    return ApprovalsDropdown.isUser(selectedItem) ? this.usersInput : this.groupsInput;
  }

  createToken(selectedItem, newValue) {
    if (this.getInput(selectedItem).value.includes(selectedItem.dataset.id)) return;

    const token = document.createElement('li');
    token.classList.add('token');
    this.tokenContainer.insertBefore(token, this.inputToken);

    return token;
  }

  static isUser(element) {
    return element.dataset.type === 'user';
  }

  static setInput(input, newValue) {
    let value = input.value;

    if (value.includes(newValue)) return;

    if (value.length > 0) value += ',';
    value += newValue;

    /* eslint-disable no-param-reassign */
    input.value = value;
    /* eslint-enable no-param-reassign */
  }

  static requestError() {
    /* eslint-disable no-new */
    new Flash('An error occured fetching the dropdown data.');
    /* eslint-enable no-new */
  }
}

export default ApprovalsDropdown;
