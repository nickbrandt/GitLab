import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { createStoreOptions } from 'ee/approvals/stores';
import MREditModule from 'ee/approvals/stores/modules/mr_edit';
import MREditApp from 'ee/approvals/components/mr_edit/app.vue';
import MRRules from 'ee/approvals/components/mr_edit/mr_rules.vue';
import MRRulesHiddenInputs from 'ee/approvals/components/mr_edit/mr_rules_hidden_inputs.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('EE Approvals MREditApp', () => {
  let wrapper;
  let store;

  const factory = () => {
    wrapper = mount(localVue.extend(MREditApp), {
      localVue,
      store: new Vuex.Store(store),
    });
  };

  beforeEach(() => {
    store = createStoreOptions(MREditModule());
    store.modules.approvals.state.hasLoaded = true;
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with empty rules', () => {
    beforeEach(() => {
      store.modules.approvals.state.rules = [];
      factory();
    });

    it('does not render MR rules', () => {
      expect(wrapper.find(MRRules).exists()).toBe(true);
    });

    it('renders hidden inputs', () => {
      expect(wrapper.find(MRRulesHiddenInputs).exists()).toBe(true);
    });
  });

  describe('with rules', () => {
    beforeEach(() => {
      store.modules.approvals.state.rules = [{ id: 7, approvers: [] }];
      factory();
    });

    it('renders MR rules', () => {
      expect(wrapper.find(MRRules).exists()).toBe(true);
    });

    it('renders hidden inputs', () => {
      expect(wrapper.find(MRRulesHiddenInputs).exists()).toBe(true);
    });
  });
});
