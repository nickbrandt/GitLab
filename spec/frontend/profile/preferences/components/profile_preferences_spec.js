import { shallowMount } from '@vue/test-utils';

import ProfilePreferences from '~/profile/preferences/components/profile_preferences.vue';
import IntegrationView from '~/profile/preferences/components/integration_view.vue';
import {
  languageChoices,
  firstDayOfWeekChoicesWithDefault,
  integrationViews,
  userFields,
  featureFlags,
} from '../mock_data';

describe('ProfilePreferences component', () => {
  let wrapper;
  const defaultProvide = {
    languageChoices,
    firstDayOfWeekChoicesWithDefault,
    integrationViews: [],
    userFields,
    featureFlags: {},
  };

  function createComponent(options = {}) {
    const { props = {}, provide = {} } = options;
    return shallowMount(ProfilePreferences, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
      propsData: props,
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('Integrations section', () => {
    it('should not render', () => {
      wrapper = createComponent();
      const views = wrapper.findAll(IntegrationView);
      const divider = wrapper.find('[data-testid="profile-preferences-integrations-rule"]');
      const heading = wrapper.find('[data-testid="profile-preferences-integrations-heading"]');

      expect(divider.exists()).toBe(false);
      expect(heading.exists()).toBe(false);
      expect(views).toHaveLength(0);
    });

    it('should render', () => {
      wrapper = createComponent({ provide: { integrationViews } });
      const divider = wrapper.find('[data-testid="profile-preferences-integrations-rule"]');
      const heading = wrapper.find('[data-testid="profile-preferences-integrations-heading"]');
      const views = wrapper.findAll(IntegrationView);

      expect(divider.exists()).toBe(true);
      expect(heading.exists()).toBe(true);
      expect(views).toHaveLength(integrationViews.length);
    });
  });

  describe('with `userTimeSettings` feature flag enabled', () => {
    it('should render user time settings', () => {
      wrapper = createComponent({ provide: { featureFlags } });
      const userTimeSettingsRule = wrapper.find('[data-testid="user-time-settings-rule"]');
      const userTimeSettingsHeading = wrapper.find('[data-testid="user-time-settings-heading"]');
      const userTimeSettingsOption = wrapper.find('[data-testid="user-time-settings-option"]');
      expect(userTimeSettingsRule.exists()).toBe(true);
      expect(userTimeSettingsHeading.exists()).toBe(true);
      expect(userTimeSettingsOption.exists()).toBe(true);
    });
  });

  describe('with `userTimeSettings` feature flag disabled', () => {
    it('should not render user time settings', () => {
      wrapper = createComponent();
      const userTimeSettingsRule = wrapper.find('[data-testid="user-time-settings-rule"]');
      const userTimeSettingsHeading = wrapper.find('[data-testid="user-time-settings-heading"]');
      const userTimeSettingsOption = wrapper.find('[data-testid="user-time-settings-option"]');
      expect(userTimeSettingsRule.exists()).toBe(false);
      expect(userTimeSettingsHeading.exists()).toBe(false);
      expect(userTimeSettingsOption.exists()).toBe(false);
    });
  });

  it('should render ProfilePreferences properly', () => {
    wrapper = createComponent({
      provide: {
        integrationViews,
        featureFlags,
      },
    });

    expect(wrapper.element).toMatchSnapshot();
  });
});
