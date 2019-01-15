import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import Rules from 'ee/approvals/components/rules_settings.vue';
import RuleControls from 'ee/approvals/components/rule_controls.vue';

const TEST_RULES = [
  { id: 1, name: 'Lorem', approvalsRequired: 2, approvers: [{ id: 7 }, { id: 8 }] },
  { id: 2, name: 'Ipsum', approvalsRequired: 0, approvers: [{ id: 9 }] },
  { id: 3, name: 'Dolarsit', approvalsRequired: 3, approvers: [] },
];

const localVue = createLocalVue();
localVue.use(Vuex);

const getRowData = tr => {
  const td = tr.findAll('td');
  const avatarList = td.at(1).find(UserAvatarList);
  const ruleControl = td.at(3).find(RuleControls);
  return {
    name: td
      .at(0)
      .find('.d-sm-block.d-none')
      .text(),
    summary: td
      .at(0)
      .find('.d-sm-none.d-block')
      .text(),
    approvers: avatarList.props('items'),
    approvalsRequired: Number(td.at(2).text()),
    ruleControl: ruleControl.props('rule'),
  };
};

describe('Approvals Rules', () => {
  let state;
  let wrapper;

  const factory = (options = {}) => {
    const store = new Vuex.Store({
      state,
    });

    wrapper = mount(localVue.extend(Rules), {
      ...options,
      store,
      localVue,
    });
  };

  beforeEach(() => {
    state = {
      rules: { rules: TEST_RULES },
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
