import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import Avatar from '~/vue_shared/components/project_avatar/default.vue';
import { TYPE_USER, TYPE_GROUP } from 'ee/approvals/constants';
import ApproversListItem from 'ee/approvals/components/approvers_list_item.vue';

const localVue = createLocalVue();
const TEST_USER = {
  id: 1,
  type: TYPE_USER,
  name: 'Lorem Ipsum',
};
const TEST_GROUP = {
  id: 1,
  type: TYPE_GROUP,
  name: 'Lorem Group',
  full_path: 'dolar/sit/amit',
};

describe('Approvals ApproversListItem', () => {
  let wrapper;

  const factory = (options = {}) => {
    wrapper = shallowMount(localVue.extend(ApproversListItem), {
      ...options,
      localVue,
    });
  };

  describe('when user', () => {
    beforeEach(() => {
      factory({
        propsData: {
          approver: TEST_USER,
        },
      });
    });

    it('renders avatar', () => {
      const avatar = wrapper.find(Avatar);

      expect(avatar.exists()).toBe(true);
      expect(avatar.props('project')).toEqual(TEST_USER);
    });

    it('renders name', () => {
      expect(wrapper.text()).toContain(TEST_USER.name);
    });

    it('when remove clicked, emits remove', () => {
      const button = wrapper.find(GlButton);
      button.vm.$emit('click');

      expect(wrapper.emittedByOrder()).toEqual([{ name: 'remove', args: [TEST_USER] }]);
    });
  });

  describe('when group', () => {
    beforeEach(() => {
      factory({
        propsData: {
          approver: TEST_GROUP,
        },
      });
    });

    it('renders full_path', () => {
      expect(wrapper.text()).toContain(TEST_GROUP.full_path);
      expect(wrapper.text()).not.toContain(TEST_GROUP.name);
    });
  });
});
