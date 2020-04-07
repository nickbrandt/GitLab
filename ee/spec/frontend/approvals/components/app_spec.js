import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlLoadingIcon, GlDeprecatedButton } from '@gitlab/ui';
import App from 'ee/approvals/components/app.vue';
import ModalRuleCreate from 'ee/approvals/components/modal_rule_create.vue';
import ModalRuleRemove from 'ee/approvals/components/modal_rule_remove.vue';
import { createStoreOptions } from 'ee/approvals/stores';
import settingsModule from 'ee/approvals/stores/modules/project_settings';

const localVue = createLocalVue();
localVue.use(Vuex);

const TEST_RULES_CLASS = 'js-fake-rules';
const APP_PREFIX = 'lorem-ipsum';

describe('EE Approvals App', () => {
  let store;
  let wrapper;
  let slots;

  const factory = () => {
    wrapper = shallowMount(localVue.extend(App), {
      localVue,
      slots,
      store: new Vuex.Store(store),
    });
  };
  const findAddButton = () => wrapper.find(GlDeprecatedButton);
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findRules = () => wrapper.find(`.${TEST_RULES_CLASS}`);

  beforeEach(() => {
    slots = {
      rules: `<div class="${TEST_RULES_CLASS}">These are the rules!</div>`,
    };

    store = createStoreOptions(settingsModule(), {
      canEdit: true,
      prefix: APP_PREFIX,
    });

    store.modules.approvals.actions = {
      fetchRules: jest.fn(),
    };

    jest.spyOn(store.modules.approvals.actions, 'fetchRules');
    jest.spyOn(store.modules.createModal.actions, 'open');
  });

  describe('targetBranch', () => {
    const targetBranchName = 'development';

    beforeEach(() => {
      store.state.settings.mrCreateTargetBranch = targetBranchName;
    });

    it('passes the target branch name in fetchRules for MR create path', () => {
      store.state.settings.prefix = 'mr-edit';
      store.state.settings.mrSettingsPath = null;
      factory();

      expect(store.modules.approvals.actions.fetchRules).toHaveBeenCalledWith(
        expect.anything(),
        targetBranchName,
        undefined,
      );
    });

    it('does not pass the target branch name in fetchRules for MR edit path', () => {
      store.state.settings.prefix = 'mr-edit';
      store.state.settings.mrSettingsPath = 'some/path';
      factory();

      expect(store.modules.approvals.actions.fetchRules).toHaveBeenCalledWith(
        expect.anything(),
        null,
        undefined,
      );
    });

    it('does not pass the target branch name in fetchRules for project settings path', () => {
      store.state.settings.prefix = 'project-settings';
      factory();

      expect(store.modules.approvals.actions.fetchRules).toHaveBeenCalledWith(
        expect.anything(),
        null,
        undefined,
      );
    });
  });

  describe('when allow multi rule', () => {
    beforeEach(() => {
      store.state.settings.allowMultiRule = true;
    });

    it('dispatches fetchRules action on created', () => {
      expect(store.modules.approvals.actions.fetchRules).not.toHaveBeenCalled();

      factory();

      expect(store.modules.approvals.actions.fetchRules).toHaveBeenCalledTimes(1);
    });

    it('renders create modal', () => {
      factory();

      const modal = wrapper.find(ModalRuleCreate);

      expect(modal.exists()).toBe(true);
      expect(modal.props('modalId')).toBe(`${APP_PREFIX}-approvals-create-modal`);
    });

    it('renders delete modal', () => {
      factory();

      const modal = wrapper.find(ModalRuleRemove);

      expect(modal.exists()).toBe(true);
      expect(modal.props('modalId')).toBe(`${APP_PREFIX}-approvals-remove-modal`);
    });

    describe('if not loaded', () => {
      beforeEach(() => {
        store.modules.approvals.state.hasLoaded = false;
      });

      it('shows loading icon', () => {
        store.modules.approvals.state.isLoading = false;
        factory();

        expect(findLoadingIcon().exists()).toBe(true);
      });
    });

    describe('if loaded and empty', () => {
      beforeEach(() => {
        store.modules.approvals.state = {
          hasLoaded: true,
          rules: [],
          isLoading: false,
        };
      });

      it('does show Rules', () => {
        factory();

        expect(findRules().exists()).toBe(true);
      });

      it('does not show loading icon if not loading', () => {
        store.modules.approvals.state.isLoading = false;
        factory();

        expect(findLoadingIcon().exists()).toBe(false);
      });
    });

    describe('if not empty', () => {
      beforeEach(() => {
        store.modules.approvals.state.hasLoaded = true;
        store.modules.approvals.state.rules = [{ id: 1 }];
      });

      it('shows rules', () => {
        factory();

        expect(findRules().exists()).toBe(true);
      });

      it('renders add button', () => {
        factory();

        const button = findAddButton();

        expect(button.exists()).toBe(true);
        expect(button.text()).toBe('Add approval rule');
      });

      it('opens create modal when add button is clicked', () => {
        factory();

        findAddButton().vm.$emit('click');

        expect(store.modules.createModal.actions.open).toHaveBeenCalledWith(
          expect.anything(),
          null,
          undefined,
        );
      });
    });
  });

  describe('when allow only single rule', () => {
    beforeEach(() => {
      store.state.settings.allowMultiRule = false;
    });

    it('does not render add button', () => {
      factory();

      expect(findAddButton().exists()).toBe(false);
    });
  });
});
