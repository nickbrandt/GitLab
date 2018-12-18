import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import ApprovalRulesEmpty from 'ee/approvals/components/approval_rules_empty.vue';
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
    };
  });

  it('dispatches fetchRules action on created', () => {
    expect(actions.fetchRules).not.toHaveBeenCalled();

    factory();

    expect(actions.fetchRules).toHaveBeenCalledTimes(1);
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

  it('shows ApprovalsSettingsEmpty if empty', () => {
    state.rules = [];
    factory();

    expect(wrapper.find(ApprovalRulesEmpty).exists()).toBe(true);
  });

  it('does not show ApprovalsSettingsEmpty is not empty', () => {
    state.rules = [{ id: 1 }];
    factory();

    expect(wrapper.find(ApprovalRulesEmpty).exists()).toBe(false);
  });
});
