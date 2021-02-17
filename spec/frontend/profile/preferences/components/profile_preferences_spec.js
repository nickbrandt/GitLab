import { GlButton, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import IntegrationView from '~/profile/preferences/components/integration_view.vue';
import ProfilePreferences from '~/profile/preferences/components/profile_preferences.vue';
import { i18n } from '~/profile/preferences/constants';
import {
  bodyClasses,
  darkModeThemeId,
  firstDayOfWeekChoicesWithDefault,
  glFeatures,
  integrationViews,
  languageChoices,
  lightModeThemeId1,
  lightModeThemeId2,
  themes,
  userFields,
} from '../mock_data';

const expectedUrl = '/foo';

describe('ProfilePreferences component', () => {
  let wrapper;
  const defaultProvide = {
    profilePreferencesLocalizationHelpPath: '/foo',
    languageChoices,
    firstDayOfWeekChoicesWithDefault,
    integrationViews: [],
    userFields,
    bodyClasses,
    themes,
    profilePreferencesPath: '/update-profile',
    formEl: document.createElement('form'),
    glFeatures: {},
  };

  function createComponent(options = {}) {
    const { props = {}, provide = {}, attachTo } = options;
    return extendedWrapper(
      shallowMount(ProfilePreferences, {
        provide: {
          ...defaultProvide,
          ...provide,
        },
        propsData: props,
        stubs: {
          GlSprintf,
        },
        attachTo,
      }),
    );
  }

  function findLocalizationAnchor() {
    return wrapper.find('#localization');
  }

  function findUserLanguageOptionList() {
    return wrapper.findAll('[data-testid="user-preferred-language-option"]');
  }

  function findUserLanguageSelectedOption() {
    return wrapper.find('[data-testid="user-preferred-language-option"]:checked');
  }

  function findUserFirstDayOfWeekOptionList() {
    return wrapper.findAll('[data-testid="user-first-day-of-week-option"]');
  }

  function findUserFirstDayOfWeekSelectedOption() {
    return wrapper.find('[data-testid="user-first-day-of-week-option"]:checked');
  }

  function findUserTimeSettingsDivider() {
    return wrapper.findByTestId('user-time-settings-rule');
  }

  function findUserTimeSettingsHeading() {
    return wrapper.findByTestId('user-time-settings-heading');
  }

  function findUserTimeFormatOption() {
    return wrapper.findByTestId('user-time-format-option');
  }

  function findUserTimeRelativeOption() {
    return wrapper.findByTestId('user-time-relative-option');
  }

  function findIntegrationsDivider() {
    return wrapper.findByTestId('profile-preferences-integrations-rule');
  }

  function findIntegrationsHeading() {
    return wrapper.findByTestId('profile-preferences-integrations-heading');
  }

  function findIntegrationViewList() {
    return wrapper.findAll(IntegrationView);
  }

  function findSubmitButton() {
    return wrapper.findComponent(GlButton);
  }

  function createThemeInput(themeId = lightModeThemeId1) {
    const input = document.createElement('input');
    input.setAttribute('name', 'user[theme_id]');
    input.setAttribute('type', 'radio');
    input.setAttribute('value', themeId.toString());
    input.setAttribute('checked', 'checked');
    return input;
  }

  function createForm(themeInput = createThemeInput()) {
    const form = document.createElement('form');
    form.setAttribute('url', expectedUrl);
    form.setAttribute('method', 'put');
    form.appendChild(themeInput);
    return form;
  }

  function setupBody() {
    const div = document.createElement('div');
    div.classList.add('container-fluid');
    document.body.appendChild(div);
    document.body.classList.add('content-wrapper');
  }

  function findFlashError() {
    return document.querySelector('.flash-container .flash-text');
  }

  beforeEach(() => {
    setFixtures('<div class="flash-container"></div>');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('Localization Settings section', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('has an id for anchoring', () => {
      expect(findLocalizationAnchor().exists()).toBe(true);
    });

    it('allows the user to change their language preferences', async () => {
      const newChoice = 1;
      const languageOptions = findUserLanguageOptionList();
      expect(findUserLanguageSelectedOption().element.value).toBe(languageChoices[0][1]);
      await languageOptions.at(newChoice).setSelected();
      expect(findUserLanguageSelectedOption().element.value).toBe(languageChoices[newChoice][1]);
    });

    it('allows the user to change their first day of the week preferences', async () => {
      const newChoice = 1;
      const languageOptions = findUserFirstDayOfWeekOptionList();
      expect(findUserFirstDayOfWeekSelectedOption().element.value).toBe(
        firstDayOfWeekChoicesWithDefault[0][1],
      );
      await languageOptions.at(newChoice).setSelected();
      expect(findUserFirstDayOfWeekSelectedOption().element.value).toBe(
        firstDayOfWeekChoicesWithDefault[newChoice][1],
      );
    });
  });

  describe('with `userTimeSettings` feature flag enabled', () => {
    beforeEach(() => {
      wrapper = createComponent({ provide: { glFeatures } });
    });

    it('should render user time settings', () => {
      expect(findUserTimeSettingsDivider().exists()).toBe(true);
      expect(findUserTimeSettingsHeading().exists()).toBe(true);
      expect(findUserTimeFormatOption().exists()).toBe(true);
      expect(findUserTimeRelativeOption().exists()).toBe(true);
    });

    it('allows the user to toggle their time format preference', async () => {
      const userTimeFormatOption = findUserTimeFormatOption();
      expect(userTimeFormatOption.element.checked).toBe(false);
      await userTimeFormatOption.trigger('click');
      expect(userTimeFormatOption.element.checked).toBe(true);
    });

    it('allows the user to toggle their time display preference', async () => {
      const userTimeTimeRelativeOption = findUserTimeRelativeOption();
      expect(userTimeTimeRelativeOption.element.checked).toBe(false);
      await userTimeTimeRelativeOption.trigger('click');
      expect(userTimeTimeRelativeOption.element.checked).toBe(true);
    });
  });

  describe('with `userTimeSettings` feature flag disabled', () => {
    it('should not render user time settings', () => {
      wrapper = createComponent();
      expect(findUserTimeSettingsDivider().exists()).toBe(false);
      expect(findUserTimeSettingsHeading().exists()).toBe(false);
      expect(findUserTimeFormatOption().exists()).toBe(false);
      expect(findUserTimeRelativeOption().exists()).toBe(false);
    });
  });

  describe('Integrations section', () => {
    it('should not render', () => {
      wrapper = createComponent();

      expect(findIntegrationsDivider().exists()).toBe(false);
      expect(findIntegrationsHeading().exists()).toBe(false);
      expect(findIntegrationViewList()).toHaveLength(0);
    });

    it('should render', () => {
      wrapper = createComponent({ provide: { integrationViews } });

      expect(findIntegrationsDivider().exists()).toBe(true);
      expect(findIntegrationsHeading().exists()).toBe(true);
      expect(findIntegrationViewList()).toHaveLength(integrationViews.length);
    });
  });

  describe('form submit', () => {
    let form;

    beforeEach(() => {
      setupBody();
      form = createForm();
      wrapper = createComponent({ provide: { formEl: form }, attachTo: document.body });
      const beforeSendEvent = new CustomEvent('ajax:beforeSend');
      form.dispatchEvent(beforeSendEvent);
    });

    it('disables the submit button', async () => {
      await nextTick();
      const button = findSubmitButton();
      expect(button.props('disabled')).toBe(true);
    });

    it('success re-enables the submit button', async () => {
      const successEvent = new CustomEvent('ajax:success');
      form.dispatchEvent(successEvent);

      await nextTick();
      const button = findSubmitButton();
      expect(button.props('disabled')).toBe(false);
    });

    it('error re-enables the submit button', async () => {
      const errorEvent = new CustomEvent('ajax:error');
      form.dispatchEvent(errorEvent);

      await nextTick();
      const button = findSubmitButton();
      expect(button.props('disabled')).toBe(false);
    });

    it('displays the default success message', () => {
      const successEvent = new CustomEvent('ajax:success');
      form.dispatchEvent(successEvent);

      expect(findFlashError().innerText.trim()).toEqual(i18n.defaultSuccess);
    });

    it('displays the custom success message', () => {
      const message = 'foo';
      const successEvent = new CustomEvent('ajax:success', { detail: [{ message }] });
      form.dispatchEvent(successEvent);

      expect(findFlashError().innerText.trim()).toEqual(message);
    });

    it('displays the default error message', () => {
      const errorEvent = new CustomEvent('ajax:error');
      form.dispatchEvent(errorEvent);

      expect(findFlashError().innerText.trim()).toEqual(i18n.defaultError);
    });

    it('displays the custom error message', () => {
      const message = 'bar';
      const errorEvent = new CustomEvent('ajax:error', { detail: [{ message }] });
      form.dispatchEvent(errorEvent);

      expect(findFlashError().innerText.trim()).toEqual(message);
    });
  });

  describe('theme changes', () => {
    const { location } = window;

    let themeInput;
    let form;

    function setupWrapper() {
      wrapper = createComponent({ provide: { formEl: form }, attachTo: document.body });
    }

    function selectThemeId(themeId) {
      themeInput.setAttribute('value', themeId.toString());
    }

    function dispatchBeforeSendEvent() {
      const beforeSendEvent = new CustomEvent('ajax:beforeSend');
      form.dispatchEvent(beforeSendEvent);
    }

    function dispatchSuccessEvent() {
      const successEvent = new CustomEvent('ajax:success');
      form.dispatchEvent(successEvent);
    }

    beforeAll(() => {
      delete window.location;
      window.location = {
        ...location,
        reload: jest.fn(),
      };
    });

    afterAll(() => {
      window.location = location;
    });

    beforeEach(() => {
      setupBody();
      themeInput = createThemeInput();
      form = createForm(themeInput);
    });

    it('reloads the page when switching from light to dark mode', async () => {
      selectThemeId(lightModeThemeId1);
      setupWrapper();

      selectThemeId(darkModeThemeId);
      dispatchBeforeSendEvent();
      await nextTick();

      dispatchSuccessEvent();
      await nextTick();

      expect(window.location.reload).toHaveBeenCalledTimes(1);
    });

    it('reloads the page when switching from dark to light mode', async () => {
      selectThemeId(darkModeThemeId);
      setupWrapper();

      selectThemeId(lightModeThemeId1);
      dispatchBeforeSendEvent();
      await nextTick();

      dispatchSuccessEvent();
      await nextTick();

      expect(window.location.reload).toHaveBeenCalledTimes(1);
    });

    it('does not reload the page when switching between light mode themes', async () => {
      selectThemeId(lightModeThemeId1);
      setupWrapper();

      selectThemeId(lightModeThemeId2);
      dispatchBeforeSendEvent();
      await nextTick();

      dispatchSuccessEvent();
      await nextTick();

      expect(window.location.reload).not.toHaveBeenCalled();
    });
  });
});
