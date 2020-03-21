import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlAlert } from '@gitlab/ui';
import App from 'ee/approvals/components/target_branch_alert/app.vue';
import { createStoreOptions } from 'ee/approvals/stores';
import mrEditModule from 'ee/approvals/stores/modules/mr_edit';

const localVue = createLocalVue();

localVue.use(Vuex);

describe('Target Branch App', () => {
  let store;
  let wrapper;

  const findAlert = () => wrapper.find(GlAlert);

  const createComponent = () => {
    wrapper = shallowMount(localVue.extend(App), {
      localVue,
      store: new Vuex.Store(store),
    });
  };

  beforeEach(() => {
    store = createStoreOptions(mrEditModule());
    store.modules.targetBranchAlertModule.state.showTargetBranchAlert = true;
    store.modules.targetBranchAlertModule.actions.toggleDisplayTargetBranchAlert = jest.fn();
    store.modules.approvals.actions.fetchRules = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('GlAlert component', () => {
    it('renders component', () => {
      createComponent();
      expect(findAlert().exists()).toBe(true);
    });

    it('close alert popup when secondary action is clicked', () => {
      createComponent();
      findAlert().vm.$emit('secondaryAction');

      expect(
        store.modules.targetBranchAlertModule.actions.toggleDisplayTargetBranchAlert,
      ).toHaveBeenCalledWith(expect.anything(), false, undefined);
    });

    it('fetch rules and close alert popup when primary action is clicked', () => {
      const targetBranch = 'some-branch';
      store.modules.targetBranchAlertModule.state.targetBranch = targetBranch;
      createComponent();
      findAlert().vm.$emit('primaryAction');

      expect(store.modules.approvals.actions.fetchRules).toHaveBeenCalledWith(
        expect.anything(),
        targetBranch,
        undefined,
      );
      expect(
        store.modules.targetBranchAlertModule.actions.toggleDisplayTargetBranchAlert,
      ).toHaveBeenCalledWith(expect.anything(), false, undefined);
    });

    it.each`
      prop                     | value                     | desc
      ${'primaryButtonText'}   | ${'Charge target branch'} | ${'has a primary text'}
      ${'secondaryButtonText'} | ${'Cancel'}               | ${'has a secondary text'}
      ${'variant'}             | ${'warning'}              | ${'has the warning variant'}
    `('$desc', ({ prop, value }) => {
      createComponent();

      expect(findAlert().props(prop)).toContain(value);
    });
  });
});
