import SamlSettingsForm from 'ee/saml_providers/saml_settings_form';

describe('SamlSettingsForm', () => {
  const FIXTURE = 'groups/saml_providers/show.html';
  preloadFixtures(FIXTURE);

  beforeEach(() => {
    loadFixtures(FIXTURE);
  });

  describe('updateView', () => {
    let samlSettingsForm;

    beforeEach(() => {
      samlSettingsForm = new SamlSettingsForm('#js-saml-settings-form');
      samlSettingsForm.init();
    });

    it('disables Test button when form has changes', () => {
      samlSettingsForm.dirtyFormChecker.isDirty = true;

      expect(samlSettingsForm.testButton.hasAttribute('disabled')).toBe(false);

      samlSettingsForm.updateView();

      expect(samlSettingsForm.testButton.hasAttribute('disabled')).toBe(true);
    });

    it('re-enables Test button when form is returned to starting state', () => {
      samlSettingsForm.testButton.setAttribute('disabled', true);

      samlSettingsForm.updateView();

      expect(samlSettingsForm.testButton.hasAttribute('disabled')).toBe(false);
    });

    it('keeps Test button disabled when SAML disabled for the group', () => {
      samlSettingsForm.samlProviderEnabled = false;
      samlSettingsForm.testButton.setAttribute('disabled', true);

      samlSettingsForm.updateView();

      expect(samlSettingsForm.testButton.hasAttribute('disabled')).toBe(true);
    });
  });
});
