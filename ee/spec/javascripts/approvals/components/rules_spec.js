import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import Rules from 'ee/approvals/components/rules.vue';

const TEST_RULES = [
  { id: 1, name: 'Lorem', approvalsRequired: 2, approvers: [{ id: 7 }, { id: 8 }] },
  { id: 2, name: 'Ipsum', approvalsRequired: 0, approvers: [{ id: 9 }] },
  { id: 3, name: 'Dolarsit', approvalsRequired: 3, approvers: [] },
];

const localVue = createLocalVue();
const getRowData = tr => {
  const td = tr.findAll('td');
  const avatarList = td.at(1).find(UserAvatarList);
  return {
    name: td
      .at(0)
      .find('.d-sm-block.d-none')
      .text(),
    summary: td
      .at(0)
      .find('.d-sm-none.d-block')
      .text(),
    approvers: avatarList.exists() ? avatarList.props('items') : td.at(1).text(),
    approvalsRequired: Number(td.at(2).text()),
  };
};
const findButton = (tr, icon) => {
  const buttons = tr.findAll(GlButton);

  return buttons.filter(x => x.find(Icon).props('name') === icon).at(0);
};

describe('Approvals Rules', () => {
  let wrapper;

  const factory = (options = {}) => {
    const propsData = {
      rules: TEST_RULES,
      ...options.propsData,
    };

    wrapper = shallowMount(localVue.extend(Rules), {
      ...options,
      localVue,
      propsData,
    });
  };

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
        approvers: rule.approvers.length ? rule.approvers : 'None',
      })),
    );
  });

  it('when edit is clicked, emits edit', () => {
    const idx = 2;
    const rule = TEST_RULES[idx];

    factory();

    const tr = wrapper.findAll('tbody tr').at(idx);
    const editButton = findButton(tr, 'pencil');
    editButton.vm.$emit('click');

    expect(wrapper.emittedByOrder()).toEqual([{ name: 'edit', args: [rule] }]);
  });

  it('when remove is clicked, emits remove', () => {
    const idx = 1;
    const rule = TEST_RULES[idx];

    factory();

    const tr = wrapper.findAll('tbody tr').at(idx);
    const removeButton = findButton(tr, 'remove');
    removeButton.vm.$emit('click');

    expect(wrapper.emittedByOrder()).toEqual([{ name: 'remove', args: [rule] }]);
  });
});
