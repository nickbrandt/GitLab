import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import { createStoreOptions } from 'ee/approvals/stores';
import projectSettingsModule from 'ee/approvals/stores/modules/project_settings';
import ProjectRules from 'ee/approvals/components/project_settings/project_rules.vue';
import RuleControls from 'ee/approvals/components/rule_controls.vue';
import { createProjectRules } from '../../mocks';

const TEST_RULES = createProjectRules();

const localVue = createLocalVue();
localVue.use(Vuex);

const findCell = (tr, name) => tr.find(`td.js-${name}`);

const getRowData = tr => {
  const summary = findCell(tr, 'summary');
  const name = findCell(tr, 'name');
  const members = findCell(tr, 'members');
  const controls = findCell(tr, 'controls');
  const approvalsRequired = findCell(tr, 'approvals-required');

  return {
    name: name.text(),
    summary: summary.text(),
    approvers: members.find(UserAvatarList).props('items'),
    approvalsRequired: Number(approvalsRequired.text()),
    ruleControl: controls.find(RuleControls).props('rule'),
  };
};

describe('Approvals ProjectRules', () => {
  let wrapper;
  let store;

  const factory = (props = {}) => {
    wrapper = mount(localVue.extend(ProjectRules), {
      propsData: props,
      sync: false,
      store: new Vuex.Store(store),
      localVue,
    });
  };

  beforeEach(() => {
    store = createStoreOptions(projectSettingsModule());
    store.modules.approvals.state.rules = TEST_RULES;
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when allow multiple rules', () => {
    beforeEach(() => {
      store.state.settings.allowMultiRule = true;
    });

    it('renders row for each rule', () => {
      factory();

      const rows = wrapper.findAll('tbody tr');
      const data = rows.wrappers.map(getRowData);

      expect(data).toEqual(
        TEST_RULES.map(rule => ({
          name: rule.name,
          summary: jasmine.stringMatching(`${rule.approvalsRequired} approval.*from ${rule.name}`),
          approvalsRequired: rule.approvalsRequired,
          approvers: rule.approvers,
          ruleControl: rule,
        })),
      );
    });
  });

  describe('when only allow single rule', () => {
    let rule;
    let row;

    beforeEach(() => {
      [rule] = TEST_RULES;
      store.modules.approvals.state.rules = [rule];

      factory();

      row = wrapper.find('tbody tr');
    });

    it('does not render name', () => {
      expect(findCell(row, 'name').exists()).toBe(false);
    });

    it('renders single summary', () => {
      expect(findCell(row, 'summary').text()).toEqual(
        `${rule.approvalsRequired} approvals required from ${rule.approvers.length} members`,
      );
    });
  });
});
