import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { createStoreOptions } from 'ee/approvals/stores';
import MREditModule from 'ee/approvals/stores/modules/mr_edit';
import MRFallbackRules from 'ee/approvals/components/mr_edit/mr_fallback_rules.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

const TEST_APPROVALS_REQUIRED = 3;
const TEST_MIN_APPROVALS_REQUIRED = 2;

describe('EE Approvals MRFallbackRules', () => {
  let wrapper;
  let store;

  const factory = () => {
    wrapper = mount(localVue.extend(MRFallbackRules), {
      localVue,
      store: new Vuex.Store(store),
      sync: false,
    });
  };

  beforeEach(() => {
    store = createStoreOptions(MREditModule());
    store.modules.approvals.state = {
      hasLoaded: true,
      rules: [],
      minFallbackApprovalsRequired: TEST_MIN_APPROVALS_REQUIRED,
      fallbackApprovalsRequired: TEST_APPROVALS_REQUIRED,
    };
    store.modules.approvals.actions.putFallbackRule = jasmine.createSpy('putFallbackRule');
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findInput = () => wrapper.find('input');

  describe('if can not edit', () => {
    beforeEach(() => {
      store.state.settings.canEdit = false;
      factory();
    });

    it('input is disabled', () => {
      expect(findInput().attributes('disabled')).toBe('disabled');
    });

    it('input has value', () => {
      expect(Number(findInput().element.value)).toBe(TEST_APPROVALS_REQUIRED);
    });
  });

  describe('if can edit', () => {
    beforeEach(() => {
      store.state.settings.canEdit = true;
      factory();
    });

    it('input is not disabled', () => {
      expect(findInput().attributes('disabled')).toBe(undefined);
    });

    it('input has value', () => {
      expect(Number(findInput().element.value)).toBe(TEST_APPROVALS_REQUIRED);
    });

    it('input has min value', () => {
      expect(Number(findInput().attributes('min'))).toBe(TEST_MIN_APPROVALS_REQUIRED);
    });

    it('input dispatches putFallbackRule on change', () => {
      const action = store.modules.approvals.actions.putFallbackRule;
      const nextValue = TEST_APPROVALS_REQUIRED + 1;

      expect(action).not.toHaveBeenCalled();

      findInput().setValue(nextValue);

      expect(action).toHaveBeenCalledWith(
        jasmine.anything(),
        {
          approvalsRequired: nextValue,
        },
        undefined,
      );
    });
  });
});
