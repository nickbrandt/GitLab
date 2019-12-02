import _ from 'underscore';
import { createLocalVue, mount } from '@vue/test-utils';
import { GlFormTextarea, GlFormCheckbox } from '@gitlab/ui';
import Form from 'ee/feature_flags/components/form.vue';
import EnvironmentsDropdown from 'ee/feature_flags/components/environments_dropdown.vue';
import {
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  INTERNAL_ID_PREFIX,
  DEFAULT_PERCENT_ROLLOUT,
} from 'ee/feature_flags/constants';
import ToggleButton from '~/vue_shared/components/toggle_button.vue';
import { featureFlag } from '../mock_data';

describe('feature flag form', () => {
  let wrapper;
  let oldGon;
  const requiredProps = {
    cancelPath: 'feature_flags',
    submitText: 'Create',
    environmentsEndpoint: '/environments.json',
  };

  beforeEach(() => {
    oldGon = window.gon;
    window.gon = { features: { featureFlagsUsersPerEnvironment: true } };
  });

  afterEach(() => {
    window.gon = oldGon;
  });

  const factory = (props = {}) => {
    const localVue = createLocalVue();

    wrapper = mount(localVue.extend(Form), {
      localVue,
      propsData: props,
      provide: {
        glFeatures: { featureFlagPermissions: true, featureFlagsUsersPerEnvironment: true },
      },
      sync: false,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render provided submitText', () => {
    factory(requiredProps);

    expect(wrapper.find('.js-ff-submit').text()).toEqual(requiredProps.submitText);
  });

  it('should render provided cancelPath', () => {
    factory(requiredProps);

    expect(wrapper.find('.js-ff-cancel').attributes('href')).toEqual(requiredProps.cancelPath);
  });

  describe('without provided data', () => {
    beforeEach(() => {
      factory(requiredProps);
    });

    it('should render name input text', () => {
      expect(wrapper.find('#feature-flag-name').exists()).toBe(true);
    });

    it('should render description textarea', () => {
      expect(wrapper.find('#feature-flag-description').exists()).toBe(true);
    });

    describe('scopes', () => {
      it('should render scopes table', () => {
        expect(wrapper.find('.js-scopes-table').exists()).toBe(true);
      });

      it('should render scopes table with a new row ', () => {
        expect(wrapper.find('.js-add-new-scope').exists()).toBe(true);
      });

      describe('status toggle', () => {
        describe('without filled text input', () => {
          it('should add a new scope with the text value empty and the status', () => {
            wrapper.find(ToggleButton).vm.$emit('change', true);

            expect(wrapper.vm.formScopes.length).toEqual(1);
            expect(wrapper.vm.formScopes[0].active).toEqual(true);
            expect(wrapper.vm.formScopes[0].environmentScope).toEqual('');

            expect(wrapper.vm.newScope).toEqual('');
          });
        });
      });
    });
  });

  describe('with provided data', () => {
    beforeEach(() => {
      factory({
        ...requiredProps,
        name: featureFlag.name,
        description: featureFlag.description,
        scopes: [
          {
            id: 1,
            active: true,
            environmentScope: 'scope',
            canUpdate: true,
            protected: false,
            rolloutStrategy: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
            rolloutPercentage: '54',
            rolloutUserIds: '123',
            shouldIncludeUserIds: true,
          },
          {
            id: 2,
            active: true,
            environmentScope: 'scope',
            canUpdate: false,
            protected: true,
            rolloutStrategy: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
            rolloutPercentage: '54',
            rolloutUserIds: '123',
            shouldIncludeUserIds: true,
          },
        ],
      });
    });

    describe('scopes', () => {
      it('should be possible to remove a scope', () => {
        expect(wrapper.find('.js-feature-flag-delete').exists()).toEqual(true);
      });

      it('renders empty row to add a new scope', () => {
        expect(wrapper.find('.js-add-new-scope').exists()).toEqual(true);
      });

      it('renders the user id checkbox', () => {
        expect(wrapper.find(GlFormCheckbox).exists()).toBe(true);
      });

      it('renders the user id text area', () => {
        expect(wrapper.find(GlFormTextarea).exists()).toBe(true);

        expect(wrapper.find(GlFormTextarea).vm.value).toBe('123');
      });

      describe('update scope', () => {
        describe('on click on toggle', () => {
          it('should update the scope', () => {
            wrapper.find(ToggleButton).vm.$emit('change', false);

            expect(_.first(wrapper.vm.formScopes).active).toBe(false);
          });
        });
      });

      describe('deleting an existing scope', () => {
        beforeEach(() => {
          wrapper.find('.js-delete-scope').trigger('click');
        });

        it('should add `shouldBeDestroyed` key the clicked scope', () => {
          expect(_.first(wrapper.vm.formScopes).shouldBeDestroyed).toBe(true);
        });

        it('should not render deleted scopes', () => {
          expect(wrapper.vm.filteredScopes).toEqual([expect.objectContaining({ id: 2 })]);
        });
      });

      describe('deleting a new scope', () => {
        it('should remove the scope from formScopes', () => {
          factory({
            ...requiredProps,
            name: 'feature_flag_1',
            description: 'this is a feature flag',
            scopes: [
              {
                environmentScope: 'new_scope',
                active: false,
                id: _.uniqueId(INTERNAL_ID_PREFIX),
                canUpdate: true,
                protected: false,
                strategies: [
                  {
                    name: ROLLOUT_STRATEGY_ALL_USERS,
                    parameters: {},
                  },
                ],
              },
            ],
          });

          wrapper.find('.js-delete-scope').trigger('click');

          expect(wrapper.vm.formScopes).toEqual([]);
        });
      });

      describe('with * scope', () => {
        beforeEach(() => {
          factory({
            ...requiredProps,
            name: 'feature_flag_1',
            description: 'this is a feature flag',
            scopes: [
              {
                environmentScope: '*',
                active: false,
                canUpdate: false,
                rolloutStrategy: ROLLOUT_STRATEGY_ALL_USERS,
                rolloutPercentage: DEFAULT_PERCENT_ROLLOUT,
              },
            ],
          });
        });

        it('renders read only name', () => {
          expect(wrapper.find('.js-scope-all').exists()).toEqual(true);
        });
      });

      describe('without permission to update', () => {
        it('should have the flag name input disabled', () => {
          const input = wrapper.find('#feature-flag-name');

          expect(input.element.disabled).toBe(true);
        });

        it('should have the flag discription text area disabled', () => {
          const textarea = wrapper.find('#feature-flag-description');

          expect(textarea.element.disabled).toBe(true);
        });

        it('should have the scope that cannot be updated be disabled', () => {
          const row = wrapper.findAll('.gl-responsive-table-row').at(2);

          expect(row.find(EnvironmentsDropdown).vm.disabled).toBe(true);
          expect(row.find(ToggleButton).vm.disabledInput).toBe(true);
          expect(row.find('.js-delete-scope').exists()).toBe(false);
        });
      });
    });

    describe('on submit', () => {
      const selectFirstRolloutStrategyOption = dropdownIndex => {
        wrapper
          .findAll('select.js-rollout-strategy')
          .at(dropdownIndex)
          .findAll('option')
          .at(1)
          .setSelected();
      };

      beforeEach(done => {
        factory({
          ...requiredProps,
          name: 'feature_flag_1',
          description: 'this is a feature flag',
          scopes: [
            {
              id: 1,
              environmentScope: 'production',
              canUpdate: true,
              protected: true,
              active: false,
              rolloutStrategy: ROLLOUT_STRATEGY_ALL_USERS,
              rolloutPercentage: DEFAULT_PERCENT_ROLLOUT,
              rolloutUserIds: '',
            },
          ],
        });

        wrapper.vm.$nextTick(done, done.fail);
      });

      it('should emit handleSubmit with the updated data', done => {
        wrapper.find('#feature-flag-name').setValue('feature_flag_2');

        wrapper
          .find('.js-new-scope-name')
          .find(EnvironmentsDropdown)
          .vm.$emit('selectEnvironment', 'review');

        wrapper
          .find('.js-add-new-scope')
          .find(ToggleButton)
          .vm.$emit('change', true);

        wrapper.find(ToggleButton).vm.$emit('change', true);

        wrapper.vm
          .$nextTick()

          .then(() => {
            selectFirstRolloutStrategyOption(0);
            selectFirstRolloutStrategyOption(2);

            return wrapper.vm.$nextTick();
          })
          .then(() => {
            wrapper.find('.js-rollout-percentage').setValue('55');

            return wrapper.vm.$nextTick();
          })
          .then(() => {
            wrapper.find({ ref: 'submitButton' }).trigger('click');

            const data = wrapper.emitted().handleSubmit[0][0];

            expect(data.name).toEqual('feature_flag_2');
            expect(data.description).toEqual('this is a feature flag');

            expect(data.scopes).toEqual([
              {
                id: 1,
                active: true,
                environmentScope: 'production',
                canUpdate: true,
                protected: true,
                rolloutStrategy: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
                rolloutPercentage: '55',
                rolloutUserIds: '',
              },
              {
                id: expect.any(String),
                active: false,
                environmentScope: 'review',
                canUpdate: true,
                protected: false,
                rolloutStrategy: ROLLOUT_STRATEGY_ALL_USERS,
                rolloutPercentage: DEFAULT_PERCENT_ROLLOUT,
                rolloutUserIds: '',
              },
              {
                id: expect.any(String),
                active: true,
                environmentScope: '',
                canUpdate: true,
                protected: false,
                rolloutStrategy: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
                rolloutPercentage: DEFAULT_PERCENT_ROLLOUT,
                rolloutUserIds: '',
              },
            ]);
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });
});
