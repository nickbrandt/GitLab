import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import ProjectRules from 'ee/approvals/components/project_settings/project_rules.vue';
import RuleControls from 'ee/approvals/components/rule_controls.vue';

const TEST_RULES = [
  { id: 1, name: 'Lorem', approvalsRequired: 2, approvers: [{ id: 7 }, { id: 8 }] },
  { id: 2, name: 'Ipsum', approvalsRequired: 0, approvers: [{ id: 9 }] },
  { id: 3, name: 'Dolarsit', approvalsRequired: 3, approvers: [] },
];

const localVue = createLocalVue();
localVue.use(Vuex);

const findCell = (tr, name) => tr.find(`td[data-name=${name}]`);

const getRowData = tr => {
  const name = findCell(tr, 'name');
  const members = findCell(tr, 'members');
  const controls = findCell(tr, 'controls');
  const approvalsRequired = findCell(tr, 'approvals_required');

  return {
    name: name.find('.d-sm-block.d-none').text(),
    summary: name.find('.d-sm-none.d-block').text(),
    approvers: members.find(UserAvatarList).props('items'),
    approvalsRequired: Number(approvalsRequired.text()),
    ruleControl: controls.find(RuleControls).props('rule'),
  };
};

describe('Approvals ProjectRules', () => {
  let state;
  let wrapper;

  const factory = (options = {}) => {
    const store = new Vuex.Store({
      state,
    });

    wrapper = mount(localVue.extend(ProjectRules), {
      ...options,
      store,
      localVue,
    });
  };

  beforeEach(() => {
    state = {
      approvals: { rules: TEST_RULES },
    };
  });

  afterEach(() => {
    wrapper.destroy();
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
