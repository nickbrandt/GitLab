import { GlAvatar } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

import GroupItemName from '~/jira_connect/components/group_item_name.vue';
import { mockGroup1 } from '../mock_data';

describe('GroupItemName', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = extendedWrapper(
      shallowMount(GroupItemName, {
        propsData: {
          group: mockGroup1,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlAvatar = () => wrapper.findComponent(GlAvatar);
  const findGroupName = () => wrapper.findByTestId('group-list-item-name');
  const findGroupDescription = () => wrapper.findByTestId('group-list-item-description');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders group avatar', () => {
      expect(findGlAvatar().exists()).toBe(true);
      expect(findGlAvatar().props('src')).toBe(mockGroup1.avatar_url);
    });

    it('renders group name', () => {
      expect(findGroupName().text()).toBe(mockGroup1.full_name);
    });

    it('renders group description', () => {
      expect(findGroupDescription().text()).toBe(mockGroup1.description);
    });
  });
});
