import { mount } from '@vue/test-utils';
import * as timeago from 'timeago.js';
import UserListsTable from 'ee/feature_flags/components/user_lists_table.vue';
import { userList } from '../mock_data';

jest.mock('timeago.js', () => ({
  format: jest.fn().mockReturnValue('2 weeks ago'),
  register: jest.fn(),
}));

describe('User Lists Table', () => {
  let wrapper;
  let userLists;

  beforeEach(() => {
    userLists = new Array(5).fill(userList).map((x, i) => ({ ...x, id: i }));
    wrapper = mount(UserListsTable, {
      propsData: { userLists },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should display the details of a user list', () => {
    expect(wrapper.find('[data-testid="ffUserListName"]').text()).toBe(userList.name);
    expect(wrapper.find('[data-testid="ffUserListIds"]').text()).toBe(
      userList.user_xids.replace(/,/g, ', '),
    );
    expect(wrapper.find('[data-testid="ffUserListTimestamp"]').text()).toBe('created 2 weeks ago');
    expect(timeago.format).toHaveBeenCalledWith(userList.created_at);
  });

  it('should set the title for a tooltip on the created stamp', () => {
    expect(wrapper.find('[data-testid="ffUserListTimestamp"]').attributes('title')).toBe(
      'Feb 4, 2020 8:13am GMT+0000',
    );
  });

  it('should display a user list entry per user list', () => {
    const lists = wrapper.findAll('[data-testid="ffUserList"]');
    expect(lists).toHaveLength(5);
    lists.wrappers.forEach(list => {
      expect(list.contains('[data-testid="ffUserListName"]')).toBe(true);
      expect(list.contains('[data-testid="ffUserListIds"]')).toBe(true);
      expect(list.contains('[data-testid="ffUserListTimestamp"]')).toBe(true);
    });
  });
});
