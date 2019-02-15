import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { createStoreOptions } from 'ee/approvals/stores';
import MREditModule from 'ee/approvals/stores/modules/mr_edit';
import MRRules from 'ee/approvals/components/mr_edit/mr_rules.vue';
import Rules from 'ee/approvals/components/rules.vue';
import RuleControls from 'ee/approvals/components/rule_controls.vue';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import { createMRRule, createMRRuleWithSource } from '../../mocks';

const { HEADERS } = Rules;

const localVue = createLocalVue();
localVue.use(Vuex);

describe('EE Approvals MRRules', () => {
  let wrapper;
  let store;

  const factory = () => {
    wrapper = mount(localVue.extend(MRRules), {
      localVue,
      store: new Vuex.Store(store),
      sync: false,
    });
  };

  const findHeaders = () => wrapper.findAll('thead th').wrappers.map(x => x.text());
  const findRuleName = () => wrapper.find('td.js-name');
  const findRuleMembers = () =>
    wrapper
      .find('td.js-members')
      .find(UserAvatarList)
      .props('items');
  const findRuleApprovalsRequired = () => wrapper.find('td.js-approvals-required input');
  const findRuleControls = () => wrapper.find('td.js-controls').find(RuleControls);

  beforeEach(() => {
    store = createStoreOptions(MREditModule());
    store.modules.approvals.state = {
      hasLoaded: true,
      rules: [],
    };
    store.modules.approvals.actions.putRule = jasmine.createSpy('putRule');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when allow multiple rules', () => {
    beforeEach(() => {
      store.state.settings.allowMultiRule = true;
    });

    it('renders headers', () => {
      factory();

      expect(findHeaders()).toEqual([HEADERS.name, HEADERS.members, HEADERS.approvalsRequired, '']);
    });

    describe('with sourced MR rule', () => {
      const expected = createMRRuleWithSource();

      beforeEach(() => {
        store.modules.approvals.state.rules = [createMRRuleWithSource()];

        factory();
      });

      it('shows name', () => {
        expect(findRuleName().text()).toEqual(expected.name);
      });

      it('shows members', () => {
        expect(findRuleMembers()).toEqual(expected.approvers);
      });

      it('shows approvals required input', () => {
        const approvalsRequired = findRuleApprovalsRequired();

        expect(Number(approvalsRequired.element.value)).toEqual(expected.approvalsRequired);
        expect(Number(approvalsRequired.attributes('min'))).toEqual(expected.minApprovalsRequired);
        expect(approvalsRequired.attributes('disabled')).toBeUndefined();
      });

      it('does not show controls', () => {
        const controls = findRuleControls();

        expect(controls.exists()).toBe(false);
      });

      it('dispatches putRule on change of approvals required', () => {
        const action = store.modules.approvals.actions.putRule;
        const approvalsRequired = findRuleApprovalsRequired();
        const newValue = expected.approvalsRequired + 1;

        approvalsRequired.setValue(newValue);

        expect(action).toHaveBeenCalledWith(
          jasmine.anything(),
          { id: expected.id, approvalsRequired: newValue },
          undefined,
        );
      });
    });

    describe('with custom MR rule', () => {
      const expected = createMRRule();

      beforeEach(() => {
        store.modules.approvals.state.rules = [createMRRule()];
        factory();
      });

      it('shows controls', () => {
        const controls = findRuleControls();

        expect(controls.exists()).toBe(true);
        expect(controls.props('rule')).toEqual(expected);
      });

      describe('with settings cannot edit', () => {
        beforeEach(() => {
          store.state.settings.canEdit = false;
          factory();
        });

        it('hides controls', () => {
          const controls = findRuleControls();

          expect(controls.exists()).toBe(false);
        });

        it('disables input', () => {
          const approvalsRequired = findRuleApprovalsRequired();

          expect(approvalsRequired.attributes('disabled')).toBe('disabled');
        });
      });
    });
  });

  describe('when allow single rule', () => {
    beforeEach(() => {
      store.state.settings.allowMultiRule = false;
    });

    it('does not show name header', () => {
      factory();

      expect(findHeaders()).not.toContain(HEADERS.name);
    });

    describe('with source rule', () => {
      beforeEach(() => {
        store.modules.approvals.state.rules = [createMRRuleWithSource()];
        factory();
      });

      it('does not show name', () => {
        expect(findRuleName().exists()).toBe(false);
      });

      it('shows controls', () => {
        expect(findRuleControls().exists()).toBe(true);
      });
    });
  });
});
