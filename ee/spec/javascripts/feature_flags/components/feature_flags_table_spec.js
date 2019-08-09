import Vue from 'vue';
import featureFlagsTableComponent from 'ee/feature_flags/components/feature_flags_table.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { trimText } from 'spec/helpers/text_helper';
import {
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  DEFAULT_PERCENT_ROLLOUT,
} from 'ee/feature_flags/constants';

describe('Feature Flag table', () => {
  let Component;
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('with an active scope and a standard rollout strategy', () => {
    beforeEach(() => {
      Component = Vue.extend(featureFlagsTableComponent);

      vm = mountComponent(Component, {
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
                rolloutStrategy: ROLLOUT_STRATEGY_ALL_USERS,
                rolloutPercentage: DEFAULT_PERCENT_ROLLOUT,
                shouldBeDestroyed: false,
              },
            ],
          },
        ],
        csrfToken: 'fakeToken',
      });
    });

    it('Should render a table', () => {
      expect(vm.$el.getAttribute('class')).toContain('table-holder');
    });

    it('Should render rows', () => {
      expect(vm.$el.querySelector('.gl-responsive-table-row')).not.toBeNull();
    });

    it('Should render a status column', () => {
      expect(vm.$el.querySelector('.js-feature-flag-status')).not.toBeNull();
      expect(trimText(vm.$el.querySelector('.js-feature-flag-status').textContent)).toEqual(
        'Active',
      );
    });

    it('Should render a feature flag column', () => {
      expect(vm.$el.querySelector('.js-feature-flag-title')).not.toBeNull();
      expect(trimText(vm.$el.querySelector('.feature-flag-name').textContent)).toEqual('flag name');
      expect(trimText(vm.$el.querySelector('.feature-flag-description').textContent)).toEqual(
        'flag description',
      );
    });

    it('should render an environments specs column', () => {
      const envColumn = vm.$el.querySelector('.js-feature-flag-environments');

      expect(envColumn).toBeDefined();
      expect(trimText(envColumn.textContent)).toBe('scope');
    });

    it('should render an environments specs badge with active class', () => {
      const envColumn = vm.$el.querySelector('.js-feature-flag-environments');

      expect(trimText(envColumn.querySelector('.badge-active').textContent)).toBe('scope');
    });

    it('should render an actions column', () => {
      expect(vm.$el.querySelector('.table-action-buttons')).not.toBeNull();
      expect(vm.$el.querySelector('.js-feature-flag-delete-button')).not.toBeNull();
      expect(vm.$el.querySelector('.js-feature-flag-edit-button')).not.toBeNull();
      expect(vm.$el.querySelector('.js-feature-flag-edit-button').getAttribute('href')).toEqual(
        'edit/path',
      );
    });
  });

  describe('with an active scope and a percentage rollout strategy', () => {
    beforeEach(() => {
      Component = Vue.extend(featureFlagsTableComponent);

      vm = mountComponent(Component, {
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
      });
    });

    it('should render an environments specs badge with percentage', () => {
      const envColumn = vm.$el.querySelector('.js-feature-flag-environments');

      expect(trimText(envColumn.querySelector('.badge').textContent)).toBe('scope: 54%');
    });
  });

  describe('with an inactive scope', () => {
    beforeEach(() => {
      Component = Vue.extend(featureFlagsTableComponent);

      vm = mountComponent(Component, {
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
      });
    });

    it('should render an environments specs badge with inactive class', () => {
      const envColumn = vm.$el.querySelector('.js-feature-flag-environments');

      expect(trimText(envColumn.querySelector('.badge-inactive').textContent)).toBe('scope');
    });
  });
});
