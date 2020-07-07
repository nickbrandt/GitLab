import states from '../../constants/show';
import * as types from './mutation_types';

export default {
  [types.REQUEST_USER_LIST](state) {
    state.state = states.LOADING;
  },
  [types.RECEIVE_USER_LIST_SUCCESS](state, userList) {
    state.state = states.SUCCESS;
    state.userIds = userList.user_xids?.length > 0 ? userList.user_xids.split(',') : [];
    state.userList = userList;
  },
  [types.RECEIVE_USER_LIST_ERROR](state) {
    state.state = states.ERROR;
  },
  [types.DISMISS_ERROR_ALERT](state) {
    state.state = states.ERROR_DISMISSED;
  },
};
