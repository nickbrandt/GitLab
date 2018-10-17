import SamlSettingsForm from 'ee/saml_providers/saml_settings_form';

document.addEventListener('DOMContentLoaded', () => {
  new SamlSettingsForm('#js-saml-settings-form').init();
});
