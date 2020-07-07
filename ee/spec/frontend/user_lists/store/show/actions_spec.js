import testAction from 'helpers/vuex_action_helper';
import Api from 'ee/api';
import createState from 'ee/user_lists/store/show/state';
import * as types from 'ee/user_lists/store/show/mutation_types';
import * as actions from 'ee/user_lists/store/show/actions';
import { userList } from 'ee_jest/feature_flags/mock_data';

jest.mock('ee/api');

describe('User Lists Show Actions', () => {
  let mockState;

  beforeEach(() => {
    mockState = createState({ projectId: '1', userListIid: '2' });
  });

  describe('fetchUserList', () => {
    it('commits REQUEST_USER_LIST and RECEIVE_USER_LIST_SUCCESS on success', () => {
      Api.fetchFeatureFlagUserList.mockResolvedValue({ data: userList });
      return testAction(
        actions.fetchUserList,
        undefined,
        mockState,
        [
          { type: types.REQUEST_USER_LIST },
          { type: types.RECEIVE_USER_LIST_SUCCESS, payload: userList },
        ],
        [],
        () => expect(Api.fetchFeatureFlagUserList).toHaveBeenCalledWith('1', '2'),
      );
    });

    it('commits REQUEST_USER_LIST and RECEIVE_USER_LIST_ERROR on error', () => {
      Api.fetchFeatureFlagUserList.mockRejectedValue({ message: 'fail' });
      return testAction(
        actions.fetchUserList,
        undefined,
        mockState,
        [{ type: types.REQUEST_USER_LIST }, { type: types.RECEIVE_USER_LIST_ERROR }],
        [],
      );
    });
  });

  describe('dismissErrorAlert', () => {
    it('commits DISMISS_ERROR_ALERT', () => {
      return testAction(
        actions.dismissErrorAlert,
        undefined,
        mockState,
        [{ type: types.DISMISS_ERROR_ALERT }],
        [],
      );
    });
  });
});
