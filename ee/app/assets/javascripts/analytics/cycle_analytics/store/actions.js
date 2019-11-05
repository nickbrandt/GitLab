import axios from '~/lib/utils/axios_utils';
import createFlash, { hideFlash } from '~/flash';
import { __ } from '~/locale';
import Api from '~/api';
import httpStatus from '~/lib/utils/http_status';
import * as types from './mutation_types';
import { nestQueryStringKeys } from '../utils';

const removeError = () => {
  const flashEl = document.querySelector('.flash-alert');
  if (flashEl) {
    hideFlash(flashEl);
  }
};

export const setCycleAnalyticsDataEndpoint = ({ commit }, groupPath) =>
  commit(types.SET_CYCLE_ANALYTICS_DATA_ENDPOINT, groupPath);

export const setStageDataEndpoint = ({ commit }, stageSlug) =>
  commit(types.SET_STAGE_DATA_ENDPOINT, stageSlug);
export const setSelectedGroup = ({ commit }, group) => commit(types.SET_SELECTED_GROUP, group);
export const setSelectedProjects = ({ commit }, projectIds) =>
  commit(types.SET_SELECTED_PROJECTS, projectIds);
export const setSelectedStageId = ({ commit }, stageId) =>
  commit(types.SET_SELECTED_STAGE_ID, stageId);

export const setDateRange = (
  { commit, dispatch, state },
  { skipFetch = false, startDate, endDate },
) => {
  commit(types.SET_DATE_RANGE, { startDate, endDate });

  if (skipFetch) return false;

  return dispatch('fetchCycleAnalyticsData', { state, dispatch });
};

export const requestStageData = ({ commit }) => commit(types.REQUEST_STAGE_DATA);
export const receiveStageDataSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_STAGE_DATA_SUCCESS, data);

export const receiveStageDataError = ({ commit }) => {
  commit(types.RECEIVE_STAGE_DATA_ERROR);
  createFlash(__('There was an error fetching data for the selected stage'));
};

export const fetchStageData = ({ state, dispatch, getters }) => {
  const { cycleAnalyticsRequestParams = {} } = getters;
  dispatch('requestStageData');

  axios
    .get(state.endpoints.stageData, {
      params: nestQueryStringKeys(cycleAnalyticsRequestParams, 'cycle_analytics'),
    })
    .then(({ data }) => dispatch('receiveStageDataSuccess', data))
    .catch(error => dispatch('receiveStageDataError', error));
};

export const requestCycleAnalyticsData = ({ commit }) => commit(types.REQUEST_CYCLE_ANALYTICS_DATA);
export const receiveCycleAnalyticsDataSuccess = ({ commit }) =>
  commit(types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS);

export const receiveCycleAnalyticsDataError = ({ commit }, { response }) => {
  const { status } = response;
  commit(types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR, status);

  if (status !== httpStatus.FORBIDDEN)
    createFlash(__('There was an error while fetching cycle analytics data.'));
};

export const fetchCycleAnalyticsData = ({ dispatch }) => {
  removeError();
  return dispatch('requestCycleAnalyticsData')
    .then(() => dispatch('fetchGroupLabels')) // fetch group label data
    .then(() => dispatch('fetchGroupStagesAndEvents')) // fetch stage data
    .then(() => dispatch('fetchSummaryData')) // fetch summary data and stage medians
    .then(() => dispatch('receiveCycleAnalyticsDataSuccess'))
    .catch(error => dispatch('receiveCycleAnalyticsDataError', error));
};

export const requestSummaryData = ({ commit }) => commit(types.REQUEST_SUMMARY_DATA);

export const receiveSummaryDataError = ({ commit }, error) => {
  commit(types.RECEIVE_SUMMARY_DATA_ERROR, error);
  createFlash(__('There was an error while fetching cycle analytics summary data.'));
};

export const receiveSummaryDataSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_SUMMARY_DATA_SUCCESS, data);

export const fetchSummaryData = ({ state, dispatch, getters }) => {
  const { cycleAnalyticsRequestParams = {} } = getters;
  dispatch('requestSummaryData');

  return axios
    .get(state.endpoints.cycleAnalyticsData, {
      params: nestQueryStringKeys(cycleAnalyticsRequestParams, 'cycle_analytics'),
    })
    .then(({ data }) => dispatch('receiveSummaryDataSuccess', data))
    .catch(error => dispatch('receiveSummaryDataError', error));
};

export const requestGroupStagesAndEvents = ({ commit }) =>
  commit(types.REQUEST_GROUP_STAGES_AND_EVENTS);

export const hideCustomStageForm = ({ commit }) => commit(types.HIDE_CUSTOM_STAGE_FORM);
export const showCustomStageForm = ({ commit }) => commit(types.SHOW_CUSTOM_STAGE_FORM);

export const receiveGroupLabelsSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_GROUP_LABELS_SUCCESS, data);

export const receiveGroupLabelsError = ({ commit }, error) => {
  commit(types.RECEIVE_GROUP_LABELS_ERROR, error);
  createFlash(__('There was an error fetching label data for the selected group'));
};

export const requestGroupLabels = ({ commit }) => commit(types.REQUEST_GROUP_LABELS);

export const fetchGroupLabels = ({ dispatch, state }) => {
  dispatch('requestGroupLabels');
  const {
    selectedGroup: { fullPath },
  } = state;

  return Api.groupLabels(fullPath)
    .then(data => dispatch('receiveGroupLabelsSuccess', data))
    .catch(error => dispatch('receiveGroupLabelsError', error));
};

export const receiveGroupStagesAndEventsError = ({ commit }) => {
  commit(types.RECEIVE_GROUP_STAGES_AND_EVENTS_ERROR);
  createFlash(__('There was an error fetching cycle analytics stages.'));
};

export const receiveGroupStagesAndEventsSuccess = ({ state, commit, dispatch }, data) => {
  commit(types.RECEIVE_GROUP_STAGES_AND_EVENTS_SUCCESS, data);
  const { stages = [] } = state;
  if (stages && stages.length) {
    const { slug } = stages[0];
    dispatch('setStageDataEndpoint', slug);
    dispatch('fetchStageData');
  } else {
    createFlash(__('There was an error while fetching cycle analytics data.'));
  }
};

export const fetchGroupStagesAndEvents = ({ state, dispatch, getters }) => {
  const {
    cycleAnalyticsRequestParams: { created_after, project_ids },
  } = getters;
  dispatch('requestGroupStagesAndEvents');

  return axios
    .get(state.endpoints.cycleAnalyticsStagesAndEvents, {
      params: nestQueryStringKeys({ start_date: created_after, project_ids }, 'cycle_analytics'),
    })
    .then(({ data }) => dispatch('receiveGroupStagesAndEventsSuccess', data))
    .catch(error => dispatch('receiveGroupStagesAndEventsError', error));
};
