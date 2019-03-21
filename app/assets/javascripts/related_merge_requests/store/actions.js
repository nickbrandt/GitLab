import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import * as types from './mutation_types';

export const setInitialState = ({ commit }, props) => {
  commit(types.SET_INITIAL_STATE, props);
};

export const requestData = ({ commit }) => commit(types.REQUEST_DATA);

export const receiveDataSuccess = ({ commit }, data) => commit(types.RECEIVE_DATA_SUCCESS, data);

export const receiveDataError = ({ commit }) => commit(types.RECEIVE_DATA_ERROR);

export const fetchMergeRequests = ({ state, dispatch }) => {
  dispatch('requestData');

  return axios
    .get(state.apiEndpoint)
    .then(res => {
      dispatch('receiveDataSuccess', res.data);
    })
    .catch(() => {
      dispatch('receiveDataError');
      createFlash(s__('Something went wrong while fetching related merge requests.'));
    });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
