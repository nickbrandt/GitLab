import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { __ } from '~/locale';
import * as types from './mutation_types';

export const setInitialPageData = ({ commit }, data) => commit(types.SET_INITIAL_PAGE_DATA, data);

export const requestPageConfigData = ({ commit }) => commit(types.REQUEST_PAGE_CONFIG_DATA);

export const receivePageConfigDataSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_PAGE_CONFIG_DATA_SUCCESS, data);

export const receivePageConfigDataError = ({ commit }) => {
  commit(types.RECEIVE_PAGE_CONFIG_DATA_ERROR);
  createFlash(__('There was an error while fetching configuration data.'));
};

export const fetchPageConfigData = ({ dispatch, state }) => {
  dispatch('requestPageConfigData');

  const { groupPath, reportId, configEndpoint } = state;

  return axios
    .get(configEndpoint.replace('REPORT_ID', reportId), {
      params: {
        group_id: groupPath,
      },
    })
    .then(response => {
      const { data } = response;
      dispatch('receivePageConfigDataSuccess', data);
    })
    .catch(() => dispatch('receivePageConfigDataError'));
};
