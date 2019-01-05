import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlLoadingIcon, GlButton } from '@gitlab/ui';
import ModalRuleCreate from 'ee/approvals/components/modal_rule_create.vue';
import ModalRuleRemove from 'ee/approvals/components/modal_rule_remove.vue';
import Rules from 'ee/approvals/components/rules.vue';
import RulesEmpty from 'ee/approvals/components/rules_empty.vue';
import Settings from 'ee/approvals/components/settings.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('EE ApprovalsSettingsForm', () => {
  let state;
  let actions;
  let wrapper;

  const factory = () => {
    const store = new Vuex.Store({
      state,
      actions,
    });

    wrapper = shallowMount(localVue.extend(Settings), {
      localVue,
      store,
      sync: false,
    });
  };

  beforeEach(() => {
    state = {};

    actions = {
      fetchRules: jasmine.createSpy('fetchRules'),
      'createModal/open': jasmine.createSpy('createModal/open'),
      'deleteModal/open': jasmine.createSpy('deleteModal/open'),
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
    });

    it('shows RulesEmpty', () => {
      factory();

      expect(wrapper.find(RulesEmpty).exists()).toBe(true);
    });

    it('does not show Rules', () => {
      factory();

      expect(wrapper.find(Rules).exists()).toBe(false);
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

      const rules = wrapper.find(Rules);

      expect(rules.exists()).toBe(true);
      expect(rules.props('rules')).toEqual(state.rules);
    });

    it('opens create modal when edit is clicked', () => {
      factory();

      const rule = state.rules[0];
      const rules = wrapper.find(Rules);
      rules.vm.$emit('edit', rule);

      expect(actions['createModal/open']).toHaveBeenCalledWith(jasmine.anything(), rule, undefined);
    });

    it('opens delete modal when remove is clicked', () => {
      factory();

      const { id } = state.rules[0];
      const rules = wrapper.find(Rules);
      rules.vm.$emit('remove', id);

      expect(actions['deleteModal/open']).toHaveBeenCalledWith(jasmine.anything(), id, undefined);
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

      expect(wrapper.find(Rules).exists()).toBe(true);
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });
  });
});
