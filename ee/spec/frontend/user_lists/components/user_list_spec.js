import Vue from 'vue';
import Vuex from 'vuex';
import { mount } from '@vue/test-utils';
import { GlAlert, GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import Api from 'ee/api';
import { userList } from '../../feature_flags/mock_data';
import createStore from 'ee/user_lists/store/show';
import UserList from 'ee/user_lists/components/user_list.vue';

jest.mock('ee/api');

Vue.use(Vuex);

describe('User List', () => {
  let wrapper;

  const findUserIds = () => wrapper.findAll('[data-testid="user-id"]');

  const destroy = () => wrapper?.destroy();

  const factory = () => {
    destroy();

    wrapper = mount(UserList, {
      store: createStore({ projectId: '1', userListIid: '2' }),
      propsData: {
        emptyStatePath: '/empty_state.svg',
      },
    });
  };

  describe('loading', () => {
    let resolveFn;

    beforeEach(() => {
      Api.fetchFeatureFlagUserList.mockReturnValue(
        new Promise(resolve => {
          resolveFn = resolve;
        }),
      );
      factory();
    });

    afterEach(() => {
      resolveFn();
    });

    it('shows a loading icon', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('success', () => {
    let userIds;

    beforeEach(() => {
      userIds = userList.user_xids.split(',');
      Api.fetchFeatureFlagUserList.mockResolvedValueOnce({ data: userList });
      factory();

      return wrapper.vm.$nextTick();
    });

    it('requests the user list on mount', () => {
      expect(Api.fetchFeatureFlagUserList).toHaveBeenCalledWith('1', '2');
    });

    it('shows the list name', () => {
      expect(wrapper.find('h3').text()).toBe(userList.name);
    });

    it('shows a row for every id', () => {
      expect(wrapper.findAll('[data-testid="user-id-row"]')).toHaveLength(userIds.length);
    });

    it('shows one id on each row', () => {
      findUserIds().wrappers.forEach((w, i) => expect(w.text()).toBe(userIds[i]));
    });
  });

  describe('error', () => {
    const findAlert = () => wrapper.find(GlAlert);

    beforeEach(() => {
      Api.fetchFeatureFlagUserList.mockRejectedValue();
      factory();

      return wrapper.vm.$nextTick();
    });

    it('displays the alert message', () => {
      const alert = findAlert();
      expect(alert.text()).toBe('Something went wrong on our end. Please try again!');
    });

    it('can dismiss the alert', async () => {
      const alert = findAlert();
      alert.find('button').trigger('click');

      await wrapper.vm.$nextTick();

      expect(alert.exists()).toBe(false);
    });
  });

  describe('empty list', () => {
    beforeEach(() => {
      Api.fetchFeatureFlagUserList.mockResolvedValueOnce({ data: { ...userList, user_xids: '' } });
      factory();

      return wrapper.vm.$nextTick();
    });

    it('displays an empty state', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBe(true);
    });
  });
});
