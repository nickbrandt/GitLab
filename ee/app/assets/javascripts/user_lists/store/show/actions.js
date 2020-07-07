import Api from 'ee/api';
import * as types from './mutation_types';

export const fetchUserList = ({ commit, state }) => {
  commit(types.REQUEST_USER_LIST);
  return Api.fetchFeatureFlagUserList(state.projectId, state.userListIid)
    .then(response => commit(types.RECEIVE_USER_LIST_SUCCESS, response.data))
    .catch(() => commit(types.RECEIVE_USER_LIST_ERROR));
};

export const dismissErrorAlert = ({ commit }) => commit(types.DISMISS_ERROR_ALERT);
