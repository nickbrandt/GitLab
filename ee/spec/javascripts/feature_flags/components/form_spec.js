import _ from 'underscore';
import { createLocalVue, mount } from '@vue/test-utils';
import Form from 'ee/feature_flags/components/form.vue';
import ToggleButton from '~/vue_shared/components/toggle_button.vue';
import EnvironmentsDropdown from 'ee/feature_flags/components/environments_dropdown.vue';
import { internalKeyID } from 'ee/feature_flags/store/modules/helpers';

describe('feature flag form', () => {
  let wrapper;
  const requiredProps = {
    cancelPath: 'feature_flags',
    submitText: 'Create',
    environmentsEndpoint: '/environments.json',
  };

  const factory = (props = {}) => {
    const localVue = createLocalVue();

    wrapper = mount(localVue.extend(Form), {
      localVue,
      propsData: props,
      sync: false,
    });
  };

  beforeAll(() => {
    gon.features = { featureFlagPermissions: true };
  });

  afterAll(() => {
    gon.features = null;
  });

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
            expect(wrapper.vm.formScopes[0].environment_scope).toEqual('');

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
        name: 'feature_flag_1',
        description: 'this is a feature flag',
        scopes: [
          {
            environment_scope: 'production',
            active: false,
            can_update: true,
            protected: true,
            id: 2,
          },
          {
            environment_scope: 'review',
            active: true,
            can_update: true,
            protected: false,
            id: 4,
          },
          {
            environment_scope: 'staging',
            active: true,
            can_update: false,
            protected: true,
            id: 5,
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

      describe('update scope', () => {
        describe('on click on toggle', () => {
          it('should update the scope', () => {
            wrapper.find(ToggleButton).vm.$emit('change', true);

            expect(wrapper.vm.formScopes).toEqual([
              {
                active: true,
                environment_scope: 'production',
                id: 2,
                can_update: true,
                protected: true,
              },
              {
                active: true,
                environment_scope: 'review',
                id: 4,
                can_update: true,
                protected: false,
              },
              {
                environment_scope: 'staging',
                active: true,
                can_update: false,
                protected: true,
                id: 5,
              },
            ]);

            expect(wrapper.vm.newScope).toEqual('');
          });
        });
      });

      describe('deleting an existing scope', () => {
        beforeEach(() => {
          wrapper.find('.js-delete-scope').trigger('click');
        });

        it('should add `_destroy` key the clicked scope', () => {
          expect(wrapper.vm.formScopes).toEqual([
            {
              environment_scope: 'production',
              active: false,
              _destroy: true,
              id: 2,
              can_update: true,
              protected: true,
            },
            {
              active: true,
              environment_scope: 'review',
              id: 4,
              can_update: true,
              protected: false,
            },
            {
              environment_scope: 'staging',
              active: true,
              can_update: false,
              protected: true,
              id: 5,
            },
          ]);
        });

        it('should not render deleted scopes', () => {
          expect(wrapper.vm.filteredScopes).toEqual([
            {
              active: true,
              environment_scope: 'review',
              id: 4,
              can_update: true,
              protected: false,
            },
            {
              environment_scope: 'staging',
              active: true,
              can_update: false,
              protected: true,
              id: 5,
            },
          ]);
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
                environment_scope: 'new_scope',
                active: false,
                id: _.uniqueId(internalKeyID),
                can_update: true,
                protected: false,
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
                environment_scope: '*',
                active: false,
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
          const row = wrapper.findAll('.gl-responsive-table-row').wrappers[3];

          expect(row.find(EnvironmentsDropdown).vm.disabled).toBe(true);
          expect(row.find(ToggleButton).vm.disabledInput).toBe(true);
          expect(row.find('.js-delete-scope').exists()).toBe(false);
        });
      });
    });

    describe('on submit', () => {
      beforeEach(() => {
        factory({
          ...requiredProps,
          name: 'feature_flag_1',
          description: 'this is a feature flag',
          scopes: [
            {
              environment_scope: 'production',
              can_update: true,
              protected: true,
              active: false,
            },
          ],
        });
      });

      it('should emit handleSubmit with the updated data', () => {
        wrapper.find('#feature-flag-name').setValue('feature_flag_2');

        wrapper
          .find('.js-new-scope-name')
          .find(EnvironmentsDropdown)
          .vm.$emit('selectEnvironment', 'review');

        wrapper
          .find('.js-add-new-scope')
          .find(ToggleButton)
          .vm.$emit('change', true);

        wrapper.vm.handleSubmit();

        const data = wrapper.emitted().handleSubmit[0][0];

        expect(data.name).toEqual('feature_flag_2');
        expect(data.description).toEqual('this is a feature flag');
        expect(data.scopes.length).toEqual(3);
        expect(data.scopes[0]).toEqual({
          active: false,
          environment_scope: 'production',
          can_update: true,
          protected: true,
        });
      });
    });
  });
});
