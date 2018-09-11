import $ from 'jquery';
import DirtyFormChecker from './dirty_form_checker';

export default class SamlSettingsForm {
  constructor(formSelector) {
    this.form = document.querySelector(formSelector);
    this.enabledToggle = this.form.querySelector('#saml_provider_enabled');
    this.testButton = this.form.querySelector('#js-saml-test-button a');
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

  updateView() {
    if (this.enabled && !this.dirtyFormChecker.isDirty) {
      this.testButton.removeAttribute('disabled');
    } else {
      this.testButton.setAttribute('disabled', true);
    }
  }
}
