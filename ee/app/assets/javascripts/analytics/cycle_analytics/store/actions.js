import Api from 'ee/api';
import createFlash, { hideFlash } from '~/flash';
import { __ } from '~/locale';
import httpStatus from '~/lib/utils/http_status';
import * as types from './mutation_types';
import { nestQueryStringKeys } from '../utils';

const removeError = () => {
  const flashEl = document.querySelector('.flash-alert');
  if (flashEl) {
    hideFlash(flashEl);
  }
};
export const setFeatureFlags = ({ commit }, featureFlags) =>
  commit(types.SET_FEATURE_FLAGS, featureFlags);
export const setSelectedGroup = ({ commit }, group) => commit(types.SET_SELECTED_GROUP, group);
export const setSelectedProjects = ({ commit }, projectIds) =>
  commit(types.SET_SELECTED_PROJECTS, projectIds);
export const setSelectedStageId = ({ commit }, stageId) =>
  commit(types.SET_SELECTED_STAGE_ID, stageId);

export const setDateRange = ({ commit, dispatch }, { skipFetch = false, startDate, endDate }) => {
  commit(types.SET_DATE_RANGE, { startDate, endDate });

  if (skipFetch) return false;

  return dispatch('fetchCycleAnalyticsData');
};

export const requestStageData = ({ commit }) => commit(types.REQUEST_STAGE_DATA);
export const receiveStageDataSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_STAGE_DATA_SUCCESS, data);

export const receiveStageDataError = ({ commit }) => {
  commit(types.RECEIVE_STAGE_DATA_ERROR);
  createFlash(__('There was an error fetching data for the selected stage'));
};

export const fetchStageData = ({ state, dispatch, getters }, slug) => {
  const { cycleAnalyticsRequestParams = {} } = getters;
  dispatch('requestStageData');

  const {
    selectedGroup: { fullPath },
  } = state;

  return Api.cycleAnalyticsStageEvents(
    fullPath,
    slug,
    nestQueryStringKeys(cycleAnalyticsRequestParams, 'cycle_analytics'),
  )
    .then(({ data }) => dispatch('receiveStageDataSuccess', data))
    .catch(error => dispatch('receiveStageDataError', error));
};

export const requestCycleAnalyticsData = ({ commit }) => commit(types.REQUEST_CYCLE_ANALYTICS_DATA);
export const receiveCycleAnalyticsDataSuccess = ({ state, commit, dispatch }) => {
  commit(types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS);

  const { featureFlags: { hasDurationChart = false, hasTasksByTypeChart = false } = {} } = state;
  const promises = [];
  if (hasDurationChart) promises.push('fetchDurationData');
  if (hasTasksByTypeChart) promises.push('fetchTasksByTypeData');
  return Promise.all(promises.map(func => dispatch(func)));
};

export const receiveCycleAnalyticsDataError = ({ commit }, { response }) => {
  const { status } = response;
  commit(types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR, status);

  if (status !== httpStatus.FORBIDDEN)
    createFlash(__('There was an error while fetching cycle analytics data.'));
};

export const fetchCycleAnalyticsData = ({ dispatch }) => {
  removeError();

  return dispatch('requestCycleAnalyticsData')
    .then(() => dispatch('fetchGroupLabels'))
    .then(() => dispatch('fetchGroupStagesAndEvents'))
    .then(() => dispatch('fetchSummaryData'))
    .then(() => dispatch('receiveCycleAnalyticsDataSuccess'))
    .catch(error => dispatch('receiveCycleAnalyticsDataError', error));
};

export const hideCustomStageForm = ({ commit }) => commit(types.HIDE_CUSTOM_STAGE_FORM);
export const showCustomStageForm = ({ commit }) => commit(types.SHOW_CUSTOM_STAGE_FORM);

export const editCustomStage = ({ commit, dispatch }, initData = {}) => {
  commit(types.EDIT_CUSTOM_STAGE, initData);
  if (initData.id) {
    dispatch('setSelectedStageId', initData.id);
  }
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

  const {
    selectedGroup: { fullPath },
  } = state;

  return Api.cycleAnalyticsSummaryData(
    fullPath,
    nestQueryStringKeys(cycleAnalyticsRequestParams, 'cycle_analytics'),
  )
    .then(({ data }) => dispatch('receiveSummaryDataSuccess', data))
    .catch(error => dispatch('receiveSummaryDataError', error));
};

export const requestGroupStagesAndEvents = ({ commit }) =>
  commit(types.REQUEST_GROUP_STAGES_AND_EVENTS);

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
    dispatch('fetchStageData', slug);
  } else {
    createFlash(__('There was an error while fetching cycle analytics data.'));
  }
};

export const fetchGroupStagesAndEvents = ({ state, dispatch, getters }) => {
  const {
    selectedGroup: { fullPath },
  } = state;

  const {
    cycleAnalyticsRequestParams: { created_after, project_ids },
  } = getters;
  dispatch('requestGroupStagesAndEvents');

  return Api.cycleAnalyticsGroupStagesAndEvents(
    fullPath,
    nestQueryStringKeys({ start_date: created_after, project_ids }, 'cycle_analytics'),
  )
    .then(({ data }) => dispatch('receiveGroupStagesAndEventsSuccess', data))
    .catch(error => dispatch('receiveGroupStagesAndEventsError', error));
};

export const requestCreateCustomStage = ({ commit }) => commit(types.REQUEST_CREATE_CUSTOM_STAGE);
export const receiveCreateCustomStageSuccess = ({ commit, dispatch }, { data: { title } }) => {
  commit(types.RECEIVE_CREATE_CUSTOM_STAGE_RESPONSE);
  createFlash(__(`Your custom stage '${title}' was created`), 'notice');

  return dispatch('fetchGroupStagesAndEvents').then(() => dispatch('fetchSummaryData'));
};

export const receiveCreateCustomStageError = ({ commit }, { error, data }) => {
  commit(types.RECEIVE_CREATE_CUSTOM_STAGE_RESPONSE);

  const { name } = data;
  const { status } = error;
  // TODO: check for 403, 422 etc
  // Follow up issue to investigate https://gitlab.com/gitlab-org/gitlab/issues/36685
  const message =
    status !== httpStatus.UNPROCESSABLE_ENTITY
      ? __(`'${name}' stage already exists'`)
      : __('There was a problem saving your custom stage, please try again');

  createFlash(message);
};

export const createCustomStage = ({ dispatch, state }, data) => {
  const {
    selectedGroup: { fullPath },
  } = state;
  dispatch('requestCreateCustomStage');

  return Api.cycleAnalyticsCreateStage(fullPath, data)
    .then(response => dispatch('receiveCreateCustomStageSuccess', response))
    .catch(error => dispatch('receiveCreateCustomStageError', { error, data }));
};

export const receiveTasksByTypeDataSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS, data);

export const receiveTasksByTypeDataError = ({ commit }, error) => {
  commit(types.RECEIVE_TASKS_BY_TYPE_DATA_ERROR, error);
  createFlash(__('There was an error fetching data for the chart'));
};
export const requestTasksByTypeData = ({ commit }) => commit(types.REQUEST_TASKS_BY_TYPE_DATA);

export const fetchTasksByTypeData = ({ dispatch, state, getters }) => {
  const {
    currentGroupPath,
    cycleAnalyticsRequestParams: { created_after, created_before, project_ids },
  } = getters;

  const {
    tasksByType: { labelIds, subject },
  } = state;

  // dont request if we have no labels selected...for now
  if (labelIds.length) {
    const params = {
      group_id: currentGroupPath,
      created_after,
      created_before,
      project_ids,
      subject,
      label_ids: labelIds,
    };

    dispatch('requestTasksByTypeData');

    return Api.cycleAnalyticsTasksByType(params)
      .then(data => dispatch('receiveTasksByTypeDataSuccess', data))
      .catch(error => dispatch('receiveTasksByTypeDataError', error));
  }
  return Promise.resolve();
};

export const requestUpdateStage = ({ commit }) => commit(types.REQUEST_UPDATE_STAGE);
export const receiveUpdateStageSuccess = ({ commit, dispatch }) => {
  commit(types.RECEIVE_UPDATE_STAGE_RESPONSE);
  createFlash(__(`Stage data updated`), 'notice');

  dispatch('fetchGroupStagesAndEvents');
};

export const receiveUpdateStageError = ({ commit }) => {
  commit(types.RECEIVE_UPDATE_STAGE_RESPONSE);
  createFlash(__('There was a problem saving your custom stage, please try again'));
};

export const updateStage = ({ dispatch, state }, { id, ...rest }) => {
  const {
    selectedGroup: { fullPath },
  } = state;

  dispatch('requestUpdateStage');

  return Api.cycleAnalyticsUpdateStage(id, fullPath, { ...rest })
    .then(({ data }) => dispatch('receiveUpdateStageSuccess', data))
    .catch(error => dispatch('receiveUpdateStageError', error));
};

export const requestRemoveStage = ({ commit }) => commit(types.REQUEST_REMOVE_STAGE);
export const receiveRemoveStageSuccess = ({ commit, dispatch }) => {
  commit(types.RECEIVE_REMOVE_STAGE_RESPONSE);
  createFlash(__('Stage removed'), 'notice');
  dispatch('fetchCycleAnalyticsData');
};

export const receiveRemoveStageError = ({ commit }) => {
  commit(types.RECEIVE_REMOVE_STAGE_RESPONSE);
  createFlash(__('There was an error removing your custom stage, please try again'));
};

export const removeStage = ({ dispatch, state }, stageId) => {
  const {
    selectedGroup: { fullPath },
  } = state;

  dispatch('requestRemoveStage');

  return Api.cycleAnalyticsRemoveStage(stageId, fullPath)
    .then(() => dispatch('receiveRemoveStageSuccess'))
    .catch(error => dispatch('receiveRemoveStageError', error));
};

export const requestDurationData = ({ commit }) => commit(types.REQUEST_DURATION_DATA);

export const receiveDurationDataSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_DURATION_DATA_SUCCESS, data);

export const receiveDurationDataError = ({ commit }) => {
  commit(types.RECEIVE_DURATION_DATA_ERROR);
  createFlash(__('There was an error while fetching cycle analytics duration data.'));
};

export const fetchDurationData = ({ state, dispatch, getters }) => {
  dispatch('requestDurationData');

  const {
    stages,
    selectedGroup: { fullPath },
  } = state;

  const {
    cycleAnalyticsRequestParams: { created_after, created_before, project_ids },
  } = getters;

  return Promise.all(
    stages.map(stage => {
      const { slug } = stage;

      return Api.cycleAnalyticsDurationChart(slug, {
        group_id: fullPath,
        created_after,
        created_before,
        project_ids,
      }).then(({ data }) => ({
        slug,
        selected: true,
        data,
      }));
    }),
  )
    .then(data => {
      dispatch('receiveDurationDataSuccess', data);
    })
    .catch(() => dispatch('receiveDurationDataError'));
};

export const updateSelectedDurationChartStages = ({ state, commit }, stages) => {
  const updatedDurationStageData = state.durationData.map(stage => {
    const selected = stages.reduce((result, object) => {
      if (object.slug === stage.slug) return true;
      return result;
    }, false);

    return {
      ...stage,
      selected,
    };
  });

  commit(types.UPDATE_SELECTED_DURATION_CHART_STAGES, updatedDurationStageData);
};
