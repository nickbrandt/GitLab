import createState from 'ee/user_lists/store/show/state';
import mutations from 'ee/user_lists/store/show/mutations';
import states from 'ee/user_lists/constants/show';
import * as types from 'ee/user_lists/store/show/mutation_types';
import { userList } from 'ee_jest/feature_flags/mock_data';

describe('User Lists Show Mutations', () => {
  let mockState;

  beforeEach(() => {
    mockState = createState({ projectId: '1', userListIid: '2' });
  });

  describe(types.REQUEST_USER_LIST, () => {
    it('puts us in the loading state', () => {
      mutations[types.REQUEST_USER_LIST](mockState);

      expect(mockState.state).toBe(states.LOADING);
    });
  });

  describe(types.RECEIVE_USER_LIST_SUCCESS, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_USER_LIST_SUCCESS](mockState, userList);
    });

    it('sets the state to LOADED', () => {
      expect(mockState.state).toBe(states.SUCCESS);
    });

    it('sets the active user list', () => {
      expect(mockState.userList).toEqual(userList);
    });

    it('splits the user IDs into an Array', () => {
      expect(mockState.userIds).toEqual(userList.user_xids.split(','));
    });

    it('sets user IDs to an empty Array if an empty string is received', () => {
      mutations[types.RECEIVE_USER_LIST_SUCCESS](mockState, { ...userList, user_xids: '' });
      expect(mockState.userIds).toEqual([]);
    });
  });
  describe(types.RECEIVE_USER_LIST_ERROR, () => {
    it('sets the state to error', () => {
      mutations[types.RECEIVE_USER_LIST_ERROR](mockState);
      expect(mockState.state).toBe(states.ERROR);
    });
  });
});
