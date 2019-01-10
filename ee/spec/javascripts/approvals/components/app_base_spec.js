import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlLoadingIcon, GlButton } from '@gitlab/ui';
import RulesEmpty from 'ee/approvals/components/rules_empty.vue';
import App from 'ee/approvals/components/app_base.vue';
import ModalRuleCreate from 'ee/approvals/components/modal_rule_create.vue';
import ModalRuleRemove from 'ee/approvals/components/modal_rule_remove.vue';
import * as getters from 'ee/approvals/stores/getters';

const localVue = createLocalVue();
localVue.use(Vuex);

const TEST_RULES_CLASS = 'js-fake-rules';
const TEST_RULES_SEL = `.${TEST_RULES_CLASS}`;

describe('EE Approvals App', () => {
  let state;
  let actions;
  let wrapper;
  let slots;

  const factory = () => {
    const store = new Vuex.Store({
      state,
      actions,
      getters,
    });

    wrapper = shallowMount(localVue.extend(App), {
      localVue,
      store,
      slots,
      sync: false,
    });
  };

  beforeEach(() => {
    state = {
      settings: { canEdit: true },
      isLoading: true,
    };

    slots = {
      rules: `<div class="${TEST_RULES_CLASS}">These are the rules!</div>`,
    };

    actions = {
      fetchRules: jasmine.createSpy('fetchRules'),
      'createModal/open': jasmine.createSpy('createModal/open'),
    };
  });

  it('dispatches fetchRules action on created', () => {
    expect(actions.fetchRules).not.toHaveBeenCalled();

    factory();

    expect(actions.fetchRules).toHaveBeenCalledTimes(1);
  });

  it('renders create modal', () => {
    factory();

    const modal = wrapper.find(ModalRuleCreate);

    expect(modal.exists()).toBe(true);
    expect(modal.props('modalId')).toBe(wrapper.vm.$options.CREATE_MODAL_ID);
  });

  it('renders delete modal', () => {
    factory();

    const modal = wrapper.find(ModalRuleRemove);

    expect(modal.exists()).toBe(true);
    expect(modal.props('modalId')).toBe(wrapper.vm.$options.REMOVE_MODAL_ID);
  });

  describe('if empty', () => {
    beforeEach(() => {
      state.rules = [];
      state.isLoading = false;
    });

    it('shows RulesEmpty', () => {
      factory();

      expect(wrapper.find(RulesEmpty).exists()).toBe(true);
    });

    it('does not show Rules', () => {
      factory();

      expect(wrapper.find(`.${TEST_RULES_CLASS}`).exists()).toBe(false);
    });

    it('opens create modal if clicked', () => {
      factory();

      const empty = wrapper.find(RulesEmpty);
      empty.vm.$emit('click');

      expect(actions['createModal/open']).toHaveBeenCalledWith(jasmine.anything(), null, undefined);
    });

    it('shows loading icon if loading', () => {
      state.isLoading = true;
      factory();

      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });

    it('does not show loading icon if not loading', () => {
      state.isLoading = false;
      factory();

      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
    });
  });

  describe('if not empty', () => {
    beforeEach(() => {
      state.rules = [{ id: 1 }];
    });

    it('does not show RulesEmpty', () => {
      factory();

      expect(wrapper.find(RulesEmpty).exists()).toBe(false);
    });

    it('shows rules', () => {
      factory();

      const rules = wrapper.find(TEST_RULES_SEL);

      expect(rules.exists()).toBe(true);
    });

    it('renders add button', () => {
      factory();

      const button = wrapper.find(GlButton);

      expect(button.exists()).toBe(true);
      expect(button.text()).toBe('Add approvers');
    });

    it('opens create modal when add button is clicked', () => {
      factory();

      const button = wrapper.find(GlButton);
      button.vm.$emit('click');

      expect(actions['createModal/open']).toHaveBeenCalledWith(jasmine.anything(), null, undefined);
    });

    it('shows loading icon and rules if loading', () => {
      state.isLoading = true;
      factory();

      expect(wrapper.find(TEST_RULES_SEL).exists()).toBe(true);
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });
  });
});
