import Api from 'ee/api';
import createFlash from '~/flash';
import { __ } from '~/locale';
import httpStatus from '~/lib/utils/http_status';
import * as types from './mutation_types';

const handleErrorOrRethrow = ({ action, error }) => {
  if (error?.response?.status === httpStatus.FORBIDDEN) {
    throw error;
  }
  action();
};

export const receiveTopRankedGroupLabelsSuccess = ({ commit, dispatch }, data) => {
  commit(types.RECEIVE_TOP_RANKED_GROUP_LABELS_SUCCESS, data);
  dispatch('fetchTasksByTypeData');
};

export const receiveTopRankedGroupLabelsError = ({ commit }, error) => {
  commit(types.RECEIVE_TOP_RANKED_GROUP_LABELS_ERROR, error);
  createFlash(__('There was an error fetching the top labels for the selected group'));
};

export const requestTopRankedGroupLabels = ({ commit }) =>
  commit(types.REQUEST_TOP_RANKED_GROUP_LABELS);

export const fetchTopRankedGroupLabels = ({
  dispatch,
  state,
  getters: {
    currentGroupPath,
    cycleAnalyticsRequestParams: { created_after, created_before },
  },
}) => {
  dispatch('requestTopRankedGroupLabels');
  const { subject } = state.tasksByType;

  return Api.cycleAnalyticsTopLabels(currentGroupPath, {
    subject,
    created_after,
    created_before,
  })
    .then(({ data }) => dispatch('receiveTopRankedGroupLabelsSuccess', data))
    .catch(error =>
      handleErrorOrRethrow({
        error,
        action: () => dispatch('receiveTopRankedGroupLabelsError', error),
      }),
    );
};

export const receiveTasksByTypeDataSuccess = ({ commit }, data) => {
  commit(types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS, data);
};

export const receiveTasksByTypeDataError = ({ commit }, error) => {
  commit(types.RECEIVE_TASKS_BY_TYPE_DATA_ERROR, error);
  createFlash(__('There was an error fetching data for the tasks by type chart'));
};

export const requestTasksByTypeData = ({ commit }) => commit(types.REQUEST_TASKS_BY_TYPE_DATA);

export const fetchTasksByTypeData = ({ dispatch, state, getters }) => {
  const {
    currentGroupPath,
    cycleAnalyticsRequestParams: { created_after, created_before, project_ids },
  } = getters;

  const {
    tasksByType: { subject, selectedLabelIds },
  } = state;

  // ensure we clear any chart data currently in state
  dispatch('requestTasksByTypeData');

  // dont request if we have no labels selected...for now
  if (selectedLabelIds.length) {
    const params = {
      created_after,
      created_before,
      project_ids,
      subject,
      label_ids: selectedLabelIds,
    };

    return Api.cycleAnalyticsTasksByType(currentGroupPath, params)
      .then(({ data }) => dispatch('receiveTasksByTypeDataSuccess', data))
      .catch(error => dispatch('receiveTasksByTypeDataError', error));
  }
  return dispatch('receiveTasksByTypeDataSuccess', []);
};

export const setTasksByTypeFilters = ({ dispatch, commit }, data) => {
  commit(types.SET_TASKS_BY_TYPE_FILTERS, data);
  dispatch('fetchTopRankedGroupLabels');
};

export const initializeCycleAnalyticsSuccess = ({ commit }) =>
  commit(types.INITIALIZE_CYCLE_ANALYTICS_SUCCESS);

export const initializeCycleAnalytics = ({ dispatch, commit }, initialData = {}) => {
  commit(types.INITIALIZE_CYCLE_ANALYTICS, initialData);
  if (initialData?.group?.fullPath) {
    return dispatch('fetchCycleAnalyticsData').then(() =>
      dispatch('initializeCycleAnalyticsSuccess'),
    );
  }

  return dispatch('initializeCycleAnalyticsSuccess');
};
