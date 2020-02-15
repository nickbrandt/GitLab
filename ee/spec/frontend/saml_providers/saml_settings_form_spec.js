import SamlSettingsForm from 'ee/saml_providers/saml_settings_form';
import 'bootstrap';

describe('SamlSettingsForm', () => {
  const FIXTURE = 'groups/saml_providers/show.html';

  let samlSettingsForm;
  beforeEach(() => {
    loadFixtures(FIXTURE);
    samlSettingsForm = new SamlSettingsForm('#js-saml-settings-form');
    samlSettingsForm.init();
  });

  describe('updateView', () => {
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
      samlSettingsForm.settings.find(s => s.name === 'group-saml').value = false;
      samlSettingsForm.testButton.setAttribute('disabled', true);

      samlSettingsForm.updateView();

      expect(samlSettingsForm.testButton.hasAttribute('disabled')).toBe(true);
    });
  });

  it('correctly turns off dependent toggle', () => {
    samlSettingsForm.settings.forEach(s => {
      const { input } = s;
      input.value = true;
    });

    const enforcedGroupManagedAccountSetting = samlSettingsForm.settings.find(
      s => s.name === 'enforced-group-managed-accounts',
    );
    const prohibitForksSetting = samlSettingsForm.settings.find(
      s => s.name === 'prohibited-outer-forks',
    );

    samlSettingsForm.updateSAMLSettings();
    samlSettingsForm.updateView();
    expect(prohibitForksSetting.toggle.hasAttribute('disabled')).toBe(false);

    enforcedGroupManagedAccountSetting.input.value = false;
    samlSettingsForm.updateSAMLSettings();
    samlSettingsForm.updateView();

    expect(prohibitForksSetting.toggle.hasAttribute('disabled')).toBe(true);
    expect(prohibitForksSetting.value).toBe(false);
  });

  it('correctly turns off multiple dependent toggles', () => {
    samlSettingsForm.settings.forEach(s => {
      const { input } = s;
      input.value = true;
    });

    const [groupSamlSetting, ...otherSettings] = samlSettingsForm.settings;

    samlSettingsForm.updateSAMLSettings();
    samlSettingsForm.updateView();
    expect(samlSettingsForm.settings.map(s => s.value)).not.toContain(false);
    expect(samlSettingsForm.settings.map(s => s.toggle.hasAttribute('disabled'))).not.toContain(
      true,
    );

    groupSamlSetting.input.value = false;
    samlSettingsForm.updateSAMLSettings();
    samlSettingsForm.updateView();

    return new Promise(window.requestAnimationFrame).then(() => {
      expect(samlSettingsForm.settings.map(s => s.value)).not.toContain(true);
      expect(otherSettings.map(s => s.toggle.hasAttribute('disabled'))).not.toContain(false);
    });
  });
});
