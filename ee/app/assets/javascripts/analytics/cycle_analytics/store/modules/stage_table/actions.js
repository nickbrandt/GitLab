import Api from 'ee/api';
import createFlash from '~/flash';
import { __ } from '~/locale';
import * as types from './mutation_types';

export const requestStageData = ({ commit }) => commit(types.REQUEST_STAGE_DATA);
export const receiveStageDataSuccess = ({ commit }, data) => {
  commit(types.RECEIVE_STAGE_DATA_SUCCESS, data);
};

export const receiveStageDataError = ({ commit }) => {
  commit(types.RECEIVE_STAGE_DATA_ERROR);
  createFlash(__('There was an error fetching data for the selected stage'));
};

export const fetchStageData = ({ dispatch, rootState, rootGetters }, slug) => {
  const { cycleAnalyticsRequestParams = {} } = rootGetters;
  const {
    selectedGroup: { fullPath },
  } = rootState;

  dispatch('requestStageData');

  return Api.cycleAnalyticsStageEvents(fullPath, slug, cycleAnalyticsRequestParams)
    .then(({ data }) => dispatch('receiveStageDataSuccess', data))
    .catch(error => dispatch('receiveStageDataError', error));
};
