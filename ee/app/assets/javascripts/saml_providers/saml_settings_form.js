import $ from 'jquery';
import { __ } from '~/locale';
import DirtyFormChecker from './dirty_form_checker';
import setupToggleButtons from '~/toggle_buttons';
import { parseBoolean } from '~/lib/utils/common_utils';

const toggleIfEnabled = (samlSetting, toggle) => {
  if (samlSetting) toggle.click();
};

export default class SamlSettingsForm {
  constructor(formSelector) {
    this.form = document.querySelector(formSelector);
    this.samlEnabledToggleArea = this.form.querySelector('.js-group-saml-enabled-toggle-area');
    this.samlProviderEnabledInput = this.form.querySelector('.js-group-saml-enabled-input');
    this.samlEnforcedSSOToggleArea = this.form.querySelector(
      '.js-group-saml-enforced-sso-toggle-area',
    );
    this.samlEnforcedSSOInput = this.form.querySelector('.js-group-saml-enforced-sso-input');
    this.samlEnforcedSSOToggle = this.form.querySelector('.js-group-saml-enforced-sso-toggle');
    this.samlEnforcedSSOHelperText = this.form.querySelector(
      '.js-group-saml-enforced-sso-helper-text',
    );
    this.samlEnforcedGroupManagedAccountsToggleArea = this.form.querySelector(
      '.js-group-saml-enforced-group-managed-accounts-toggle-area',
    );
    this.samlEnforcedGroupManagedAccountsInput = this.form.querySelector(
      '.js-group-saml-enforced-group-managed-accounts-input',
    );
    this.samlEnforcedGroupManagedAccountsToggle = this.form.querySelector(
      '.js-group-saml-enforced-group-managed-accounts-toggle',
    );
    this.samlEnforcedGroupManagedAccountsHelperText = this.form.querySelector(
      '.js-group-saml-enforced-group-managed-accounts-helper-text',
    );
    this.samlEnforcedGroupManagedAccountsCallout = this.form.querySelector(
      '.js-group-saml-enforced-group-managed-accounts-callout',
    );
    this.testButtonTooltipWrapper = this.form.querySelector('#js-saml-test-button');
    this.testButton = this.testButtonTooltipWrapper.querySelector('a');
    this.dirtyFormChecker = new DirtyFormChecker(formSelector, () => this.updateView());
  }

  init() {
    this.dirtyFormChecker.init();

    setupToggleButtons(this.samlEnabledToggleArea);
    setupToggleButtons(this.samlEnforcedSSOToggleArea);
    setupToggleButtons(this.samlEnforcedGroupManagedAccountsToggleArea);
    $(this.samlProviderEnabledInput).on('trigger-change', () => this.onEnableToggle());
    $(this.samlEnforcedSSOInput).on('trigger-change', () => this.onEnableToggle());
    $(this.samlEnforcedGroupManagedAccountsInput).on('trigger-change', () => this.onEnableToggle());

    this.updateSAMLSettings();
    this.updateView();
  }

  onEnableToggle() {
    this.updateSAMLSettings();
    this.updateView();
  }

  updateSAMLSettings() {
    this.samlProviderEnabled = parseBoolean(this.samlProviderEnabledInput.value);
    this.samlEnforcedSSOEnabled = parseBoolean(this.samlEnforcedSSOInput.value);
    this.samlEnforcedGroupManagedAccountsEnabled = parseBoolean(
      this.samlEnforcedGroupManagedAccountsInput.value,
    );
  }

  testButtonTooltip() {
    if (!this.samlProviderEnabled) {
      return __('Group SAML must be enabled to test');
    }

    if (this.dirtyFormChecker.isDirty) {
      return __('Save changes before testing');
    }

    return __('Redirect to SAML provider to test configuration');
  }

  updateSAMLToggles() {
    if (!this.samlProviderEnabled) {
      toggleIfEnabled(this.samlEnforcedSSOEnabled, this.samlEnforcedSSOToggle);
      toggleIfEnabled(
        this.samlEnforcedGroupManagedAccountsEnabled,
        this.samlEnforcedGroupManagedAccountsToggle,
      );
    }

    if (!this.samlEnforcedSSOEnabled) {
      toggleIfEnabled(
        this.samlEnforcedGroupManagedAccountsEnabled,
        this.samlEnforcedGroupManagedAccountsToggle,
      );
    }

    this.samlEnforcedSSOToggle.disabled = !this.samlProviderEnabled;
    this.samlEnforcedGroupManagedAccountsToggle.disabled =
      !this.samlProviderEnabled || !this.samlEnforcedSSOEnabled;
  }

  updateHelperTextAndCallouts() {
    this.samlEnforcedSSOHelperText.style.display = this.samlProviderEnabled ? 'none' : 'block';
    this.samlEnforcedGroupManagedAccountsHelperText.style.display = this.samlEnforcedSSOEnabled
      ? 'none'
      : 'block';
    this.samlEnforcedGroupManagedAccountsCallout.style.display = this
      .samlEnforcedGroupManagedAccountsEnabled
      ? 'block'
      : 'none';
  }

  updateView() {
    if (this.samlProviderEnabled && !this.dirtyFormChecker.isDirty) {
      this.testButton.removeAttribute('disabled');
    } else {
      this.testButton.setAttribute('disabled', true);
    }

    this.updateSAMLToggles();
    this.updateHelperTextAndCallouts();

    // Update tooltip using wrapper so it works when input disabled
    this.testButtonTooltipWrapper.setAttribute('title', this.testButtonTooltip());
    $(this.testButtonTooltipWrapper).tooltip('_fixTitle');
  }
}
