import { shallowMount } from '@vue/test-utils';
import { GlFormSelect, GlFormTextarea, GlFormInput, GlToken, GlDeprecatedButton } from '@gitlab/ui';
import {
  PERCENT_ROLLOUT_GROUP_ID,
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ROLLOUT_STRATEGY_USER_ID,
} from 'ee/feature_flags/constants';
import Strategy from 'ee/feature_flags/components/strategy.vue';
import NewEnvironmentsDropdown from 'ee/feature_flags/components/new_environments_dropdown.vue';

describe('Feature flags strategy', () => {
  let wrapper;

  const factory = (
    opts = {
      propsData: {
        strategy: {},
        index: 0,
        endpoint: '',
        canDelete: true,
      },
    },
  ) => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
    wrapper = shallowMount(Strategy, opts);
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe.each`
    name                                | parameter       | value    | input
    ${ROLLOUT_STRATEGY_ALL_USERS}       | ${null}         | ${null}  | ${null}
    ${ROLLOUT_STRATEGY_PERCENT_ROLLOUT} | ${'percentage'} | ${'50'}  | ${GlFormInput}
    ${ROLLOUT_STRATEGY_USER_ID}         | ${'userIds'}    | ${'1,2'} | ${GlFormTextarea}
  `('with strategy $name', ({ name, parameter, value, input }) => {
    let propsData;
    let strategy;
    beforeEach(() => {
      const parameters = {};
      if (parameter !== null) {
        parameters[parameter] = value;
      }
      strategy = { name, parameters };
      propsData = { strategy, index: 0, endpoint: '', canDelete: true };
      factory({ propsData });
    });

    it('should set the select to match the strategy name', () => {
      expect(wrapper.find(GlFormSelect).attributes('value')).toBe(name);
    });
    it('should not show inputs for other paramters', () => {
      [GlFormTextarea, GlFormInput]
        .filter(component => component !== input)
        .map(component => wrapper.findAll(component))
        .forEach(inputWrapper => expect(inputWrapper).toHaveLength(0));
    });
    if (parameter !== null) {
      it(`should show the input for ${parameter} with the correct value`, () => {
        const inputWrapper = wrapper.find(input);
        expect(inputWrapper.exists()).toBe(true);
        expect(inputWrapper.attributes('value')).toBe(value);
      });
      it(`should emit a change event when altering ${parameter}`, () => {
        const inputWrapper = wrapper.find(input);
        inputWrapper.vm.$emit('input', '');
        expect(wrapper.emitted('change')).toEqual([
          [{ name, parameters: expect.objectContaining({ [parameter]: '' }), scopes: [] }],
        ]);
      });
    }
  });

  describe('with a strategy', () => {
    describe('with scopes defined', () => {
      let strategy;

      beforeEach(() => {
        strategy = {
          name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
          parameters: { percentage: '50' },
          scopes: [{ environmentScope: '*' }],
        };
        const propsData = { strategy, index: 0, endpoint: '', canDelete: true };
        factory({ propsData });
      });

      it('should change the parameters if a different strategy is chosen', () => {
        const select = wrapper.find(GlFormSelect);
        select.vm.$emit('input', ROLLOUT_STRATEGY_ALL_USERS);
        select.vm.$emit('change', ROLLOUT_STRATEGY_ALL_USERS);
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.find(GlFormInput).exists()).toBe(false);
          expect(wrapper.emitted('change')).toEqual([
            [
              {
                name: ROLLOUT_STRATEGY_ALL_USERS,
                parameters: {},
                scopes: [{ environmentScope: '*' }],
              },
            ],
          ]);
        });
      });

      it('should display selected scopes', () => {
        const dropdown = wrapper.find(NewEnvironmentsDropdown);
        dropdown.vm.$emit('add', 'production');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.findAll(GlToken)).toHaveLength(1);
          expect(wrapper.find(GlToken).text()).toBe('production');
        });
      });

      it('should display all selected scopes', () => {
        const dropdown = wrapper.find(NewEnvironmentsDropdown);
        dropdown.vm.$emit('add', 'production');
        dropdown.vm.$emit('add', 'staging');
        return wrapper.vm.$nextTick().then(() => {
          const tokens = wrapper.findAll(GlToken);
          expect(tokens).toHaveLength(2);
          expect(tokens.at(0).text()).toBe('production');
          expect(tokens.at(1).text()).toBe('staging');
        });
      });

      it('should emit selected scopes', () => {
        const dropdown = wrapper.find(NewEnvironmentsDropdown);
        dropdown.vm.$emit('add', 'production');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.emitted('change')).toEqual([
            [
              {
                name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
                parameters: { percentage: '50', groupId: PERCENT_ROLLOUT_GROUP_ID },
                scopes: [
                  { environmentScope: '*', shouldBeDestroyed: true },
                  { environmentScope: 'production' },
                ],
              },
            ],
          ]);
        });
      });

      it('should emit a delete if the delete button is clicked', () => {
        wrapper.find(GlDeprecatedButton).vm.$emit('click');
        expect(wrapper.emitted('delete')).toEqual([[]]);
      });

      it('should not display the delete button if can delete is false', () => {
        const propsData = { strategy, index: 0, endpoint: '', canDelete: false };
        factory({ propsData });

        expect(wrapper.find(GlDeprecatedButton).exists()).toBe(false);
      });
    });

    describe('wihtout scopes defined', () => {
      beforeEach(() => {
        const strategy = {
          name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
          parameters: { percentage: '50' },
          scopes: [],
        };
        const propsData = { strategy, index: 0, endpoint: '', canDelete: true };
        factory({ propsData });
      });

      it('should display selected scopes', () => {
        const dropdown = wrapper.find(NewEnvironmentsDropdown);
        dropdown.vm.$emit('add', 'production');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.findAll(GlToken)).toHaveLength(1);
          expect(wrapper.find(GlToken).text()).toBe('production');
        });
      });

      it('should display all selected scopes', () => {
        const dropdown = wrapper.find(NewEnvironmentsDropdown);
        dropdown.vm.$emit('add', 'production');
        dropdown.vm.$emit('add', 'staging');
        return wrapper.vm.$nextTick().then(() => {
          const tokens = wrapper.findAll(GlToken);
          expect(tokens).toHaveLength(2);
          expect(tokens.at(0).text()).toBe('production');
          expect(tokens.at(1).text()).toBe('staging');
        });
      });

      it('should emit selected scopes', () => {
        const dropdown = wrapper.find(NewEnvironmentsDropdown);
        dropdown.vm.$emit('add', 'production');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.emitted('change')).toEqual([
            [
              {
                name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
                parameters: { percentage: '50', groupId: PERCENT_ROLLOUT_GROUP_ID },
                scopes: [{ environmentScope: 'production' }],
              },
            ],
          ]);
        });
      });
    });
  });
});
