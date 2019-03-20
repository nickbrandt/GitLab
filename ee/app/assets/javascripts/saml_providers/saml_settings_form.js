import $ from 'jquery';
import { __ } from '~/locale';
import DirtyFormChecker from './dirty_form_checker';
import setupToggleButtons from '~/toggle_buttons';
import { parseBoolean } from '~/lib/utils/common_utils';

export default class SamlSettingsForm {
  constructor(formSelector) {
    this.form = document.querySelector(formSelector);
    this.samlToggleArea = this.form.querySelector('.js-group-saml-enable-toggle-area');
    this.enabledToggle = this.form.querySelector('#saml_provider_enabled');
    this.testButtonTooltipWrapper = this.form.querySelector('#js-saml-test-button');
    this.testButton = this.testButtonTooltipWrapper.querySelector('a');
    this.dirtyFormChecker = new DirtyFormChecker(formSelector, () => this.updateView());
  }

  init() {
    this.dirtyFormChecker.init();

    setupToggleButtons(this.samlToggleArea);
    $(this.enabledToggle).on('trigger-change', () => this.onEnableToggle());

    this.updateEnabled();
    this.updateView();
  }

  onEnableToggle() {
    this.updateEnabled();
    this.updateView();
  }

  updateEnabled() {
    this.enabled = parseBoolean(this.enabledToggle.value);
  }

  testButtonTooltip() {
    if (!this.enabled) {
      return __('Group SAML must be enabled to test');
    }

    if (this.dirtyFormChecker.isDirty) {
      return __('Save changes before testing');
    }

    return __('Redirect to SAML provider to test configuration');
  }

  updateView() {
    if (this.enabled && !this.dirtyFormChecker.isDirty) {
      this.testButton.removeAttribute('disabled');
    } else {
      this.testButton.setAttribute('disabled', true);
    }

    // Update tooltip using wrapper so it works when input disabled
    this.testButtonTooltipWrapper.setAttribute('title', this.testButtonTooltip());
    $(this.testButtonTooltipWrapper).tooltip('_fixTitle');
  }
}
