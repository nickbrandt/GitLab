import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlLoadingIcon, GlButton } from '@gitlab/ui';
import RulesEmpty from 'ee/approvals/components/rules_empty.vue';
import App from 'ee/approvals/components/app_base.vue';
import ModalRuleCreate from 'ee/approvals/components/modal_rule_create.vue';
import ModalRuleRemove from 'ee/approvals/components/modal_rule_remove.vue';
import { createStoreOptions } from 'ee/approvals/stores';
import settingsModule from 'ee/approvals/stores/modules/settings';

const localVue = createLocalVue();
localVue.use(Vuex);

const TEST_RULES_CLASS = 'js-fake-rules';
const TEST_RULES_SEL = `.${TEST_RULES_CLASS}`;

describe('EE Approvals App', () => {
  let store;
  let wrapper;
  let slots;

  const factory = () => {
    wrapper = shallowMount(localVue.extend(App), {
      localVue,
      slots,
      store: new Vuex.Store(store),
      sync: false,
    });
  };

  beforeEach(() => {
    slots = {
      rules: `<div class="${TEST_RULES_CLASS}">These are the rules!</div>`,
    };

    store = createStoreOptions(settingsModule(), { canEdit: true });
    store.modules.rules.actions.fetchRules = jasmine.createSpy('fetchRules');
    store.modules.createModal.actions.open = jasmine.createSpy('createModal/open');
  });

  it('dispatches fetchRules action on created', () => {
    expect(store.modules.rules.actions.fetchRules).not.toHaveBeenCalled();

    factory();

    expect(store.modules.rules.actions.fetchRules).toHaveBeenCalledTimes(1);
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
      store.modules.rules.state = {
        rules: [],
        isLoading: false,
      };
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

      expect(store.modules.createModal.actions.open).toHaveBeenCalledWith(
        jasmine.anything(),
        null,
        undefined,
      );
    });

    it('shows loading icon if loading', () => {
      store.modules.rules.state.isLoading = true;
      factory();

      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });

    it('does not show loading icon if not loading', () => {
      store.modules.rules.state.isLoading = false;
      factory();

      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
    });
  });

  describe('if not empty', () => {
    beforeEach(() => {
      store.modules.rules.state.rules = [{ id: 1 }];
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

      expect(store.modules.createModal.actions.open).toHaveBeenCalledWith(
        jasmine.anything(),
        null,
        undefined,
      );
    });

    it('shows loading icon and rules if loading', () => {
      store.modules.rules.state.isLoading = true;
      factory();

      expect(wrapper.find(TEST_RULES_SEL).exists()).toBe(true);
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });
  });
});
