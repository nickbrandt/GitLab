import $ from 'jquery';
import { __ } from '~/locale';
import DirtyFormChecker from './dirty_form_checker';

export default class SamlSettingsForm {
  constructor(formSelector) {
    this.form = document.querySelector(formSelector);
    this.enabledToggle = this.form.querySelector('#saml_provider_enabled');
    this.testButtonTooltipWrapper = this.form.querySelector('#js-saml-test-button');
    this.testButton = this.testButtonTooltipWrapper.querySelector('a');
    this.dirtyFormChecker = new DirtyFormChecker(formSelector, () => this.updateView());
  }

  init() {
    this.dirtyFormChecker.init();
    this.updateEnabled();
    this.updateView();

    this.enabledToggle.addEventListener('change', () => this.onEnableToggle());
  }

  onEnableToggle() {
    this.updateEnabled();
    this.updateView();
  }

  updateEnabled() {
    this.enabled = this.enabledToggle.checked;
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
