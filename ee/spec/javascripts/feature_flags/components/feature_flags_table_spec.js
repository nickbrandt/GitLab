import featureFlagsTableComponent from 'ee/feature_flags/components/feature_flags_table.vue';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { trimText } from 'spec/helpers/text_helper';
import {
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  DEFAULT_PERCENT_ROLLOUT,
} from 'ee/feature_flags/constants';

const localVue = createLocalVue();

describe('Feature flag table', () => {
  let Component;
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with an active scope and a standard rollout strategy', () => {
    beforeEach(() => {
      Component = localVue.extend(featureFlagsTableComponent);

      wrapper = shallowMount(Component, {
        localVue,
        provide: { glFeatures: { featureFlagIID: true } },
        propsData: {
          featureFlags: [
            {
              id: 1,
              iid: 1,
              active: true,
              name: 'flag name',
              description: 'flag description',
              destroy_path: 'destroy/path',
              edit_path: 'edit/path',
              scopes: [
                {
                  id: 1,
                  active: true,
                  environmentScope: 'scope',
                  canUpdate: true,
                  protected: false,
                  rolloutStrategy: ROLLOUT_STRATEGY_ALL_USERS,
                  rolloutPercentage: DEFAULT_PERCENT_ROLLOUT,
                  shouldBeDestroyed: false,
                },
              ],
            },
          ],
          csrfToken: 'fakeToken',
        },
      });
    });

    it('Should render a table', () => {
      expect(wrapper.classes('table-holder')).toBe(true);
    });

    it('Should render rows', () => {
      expect(wrapper.find('.gl-responsive-table-row').exists()).toBe(true);
    });

    it('should render an ID column', () => {
      expect(wrapper.find('.js-feature-flag-id').exists()).toBe(true);
      expect(trimText(wrapper.find('.js-feature-flag-id').text())).toEqual('^1');
    });

    it('Should render a status column', () => {
      expect(wrapper.find('.js-feature-flag-status').exists()).toBe(true);
      expect(trimText(wrapper.find('.js-feature-flag-status').text())).toEqual('Active');
    });

    it('Should render a feature flag column', () => {
      expect(wrapper.find('.js-feature-flag-title').exists()).toBe(true);
      expect(trimText(wrapper.find('.feature-flag-name').text())).toEqual('flag name');

      expect(trimText(wrapper.find('.feature-flag-description').text())).toEqual(
        'flag description',
      );
    });

    it('should render an environments specs column', () => {
      const envColumn = wrapper.find('.js-feature-flag-environments');

      expect(envColumn).toBeDefined();
      expect(trimText(envColumn.text())).toBe('scope');
    });

    it('should render an environments specs badge with active class', () => {
      const envColumn = wrapper.find('.js-feature-flag-environments');

      expect(trimText(envColumn.find('.badge-active').text())).toBe('scope');
    });

    it('should render an actions column', () => {
      expect(wrapper.find('.table-action-buttons').exists()).toBe(true);
      expect(wrapper.find('.js-feature-flag-delete-button').exists()).toBe(true);
      expect(wrapper.find('.js-feature-flag-edit-button').exists()).toBe(true);
      expect(wrapper.find('.js-feature-flag-edit-button').attributes('href')).toEqual('edit/path');
    });
  });

  describe('with an active scope and a percentage rollout strategy', () => {
    beforeEach(() => {
      Component = localVue.extend(featureFlagsTableComponent);

      wrapper = shallowMount(Component, {
        localVue,
        propsData: {
          featureFlags: [
            {
              id: 1,
              active: true,
              name: 'flag name',
              description: 'flag description',
              destroy_path: 'destroy/path',
              edit_path: 'edit/path',
              scopes: [
                {
                  id: 1,
                  active: true,
                  environmentScope: 'scope',
                  canUpdate: true,
                  protected: false,
                  rolloutStrategy: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
                  rolloutPercentage: '54',
                  shouldBeDestroyed: false,
                },
              ],
            },
          ],
          csrfToken: 'fakeToken',
        },
      });
    });

    it('should render an environments specs badge with percentage', () => {
      const envColumn = wrapper.find('.js-feature-flag-environments');

      expect(trimText(envColumn.find('.badge').text())).toBe('scope: 54%');
    });
  });

  describe('with an inactive scope', () => {
    beforeEach(() => {
      Component = localVue.extend(featureFlagsTableComponent);

      wrapper = shallowMount(Component, {
        localVue,
        propsData: {
          featureFlags: [
            {
              id: 1,
              active: true,
              name: 'flag name',
              description: 'flag description',
              destroy_path: 'destroy/path',
              edit_path: 'edit/path',
              scopes: [
                {
                  id: 1,
                  active: false,
                  environmentScope: 'scope',
                  canUpdate: true,
                  protected: false,
                  rolloutStrategy: ROLLOUT_STRATEGY_ALL_USERS,
                  rolloutPercentage: DEFAULT_PERCENT_ROLLOUT,
                  shouldBeDestroyed: false,
                },
              ],
            },
          ],
          csrfToken: 'fakeToken',
        },
      });
    });

    it('should render an environments specs badge with inactive class', () => {
      const envColumn = wrapper.find('.js-feature-flag-environments');

      expect(trimText(envColumn.find('.badge-inactive').text())).toBe('scope');
    });
  });
});
