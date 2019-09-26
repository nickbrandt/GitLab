import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import * as types from './mutation_types';
import { transformRawStages } from '../utils';

export default {
  [types.SET_FEATURE_FLAGS](state, featureFlags) {
    state.featureFlags = featureFlags;
  },
  [types.SET_SELECTED_GROUP](state, group) {
    state.selectedGroup = convertObjectPropsToCamelCase(group, { deep: true });
    state.selectedProjectIds = [];
  },
  [types.SET_SELECTED_PROJECTS](state, projectIds) {
    state.selectedProjectIds = projectIds;
  },
  [types.SET_SELECTED_STAGE](state, rawData) {
    state.selectedStage = convertObjectPropsToCamelCase(rawData);
  },
  [types.SET_DATE_RANGE](state, { startDate, endDate }) {
    state.startDate = startDate;
    state.endDate = endDate;
  },
  [types.UPDATE_SELECTED_DURATION_CHART_STAGES](state, updatedDurationStageData) {
    state.durationData = updatedDurationStageData;
  },
  [types.REQUEST_CYCLE_ANALYTICS_DATA](state) {
    state.isLoading = true;
    state.isCreatingCustomStage = false;
    state.isEditingCustomStage = false;
  },
  [types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS](state) {
    state.errorCode = null;
    state.isLoading = false;
  },
  [types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR](state, errCode) {
    state.errorCode = errCode;
    state.isLoading = false;
  },
  [types.REQUEST_STAGE_DATA](state) {
    state.isLoadingStage = true;
    state.isEmptyStage = false;
  },
  [types.RECEIVE_STAGE_DATA_SUCCESS](state, events = []) {
    state.currentStageEvents = events.map(fields =>
      convertObjectPropsToCamelCase(fields, { deep: true }),
    );
    state.isEmptyStage = !events.length;
    state.isLoadingStage = false;
  },
  [types.RECEIVE_STAGE_DATA_ERROR](state) {
    state.isEmptyStage = true;
    state.isLoadingStage = false;
  },
  [types.REQUEST_GROUP_LABELS](state) {
    state.labels = [];
    state.tasksByType = {
      ...state.tasksByType,
      labelIds: [],
    };
  },
  [types.REQUEST_STAGE_MEDIANS](state) {
    state.medians = {};
  },
  [types.RECEIVE_STAGE_MEDIANS_SUCCESS](state, medians = []) {
    state.medians = medians.reduce(
      (acc, { id, value }) => ({
        ...acc,
        [id]: value,
      }),
      {},
    );
  },
  [types.RECEIVE_STAGE_MEDIANS_ERROR](state) {
    state.medians = {};
  },
  [types.RECEIVE_GROUP_LABELS_SUCCESS](state, data = []) {
    const { tasksByType } = state;
    state.labels = data.map(convertObjectPropsToCamelCase);
    state.tasksByType = {
      ...tasksByType,
      labelIds: data.map(({ id }) => id),
    };
  },
  [types.RECEIVE_GROUP_LABELS_ERROR](state) {
    const { tasksByType } = state;
    state.labels = [];
    state.tasksByType = {
      ...tasksByType,
      labelIds: [],
    };
  },
  [types.SHOW_CUSTOM_STAGE_FORM](state) {
    state.isCreatingCustomStage = true;
    state.customStageFormInitData = {};
  },
  [types.EDIT_CUSTOM_STAGE](state) {
    state.isEditingCustomStage = true;
  },
  [types.HIDE_CUSTOM_STAGE_FORM](state) {
    state.isEditingCustomStage = false;
    state.isCreatingCustomStage = false;
    state.customStageFormInitData = {};
  },
  [types.SHOW_CUSTOM_STAGE_FORM](state) {
    state.isCreatingCustomStage = true;
  },
  [types.RECEIVE_SUMMARY_DATA_ERROR](state) {
    state.summary = [];
  },
  [types.REQUEST_SUMMARY_DATA](state) {
    state.summary = [];
  },
  [types.RECEIVE_SUMMARY_DATA_SUCCESS](state, data) {
    state.summary = data.map(item => ({
      ...item,
      value: item.value || '-',
    }));
  },
  [types.REQUEST_GROUP_STAGES_AND_EVENTS](state) {
    state.stages = [];
    state.customStageFormEvents = [];
  },
  [types.RECEIVE_GROUP_STAGES_AND_EVENTS_ERROR](state) {
    state.stages = [];
    state.customStageFormEvents = [];
  },
  [types.RECEIVE_GROUP_STAGES_AND_EVENTS_SUCCESS](state, data) {
    const { events = [], stages = [] } = data;
    state.stages = transformRawStages(stages.filter(({ hidden = false }) => !hidden));

    state.customStageFormEvents = events.map(ev =>
      convertObjectPropsToCamelCase(ev, { deep: true }),
    );
  },
  [types.REQUEST_TASKS_BY_TYPE_DATA](state) {
    state.isLoadingChartData = true;
  },
  [types.RECEIVE_TASKS_BY_TYPE_DATA_ERROR](state) {
    state.isLoadingChartData = false;
  },
  [types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS](state, data) {
    state.isLoadingChartData = false;
    state.tasksByType = {
      ...state.tasksByType,
      data,
    };
  },
  [types.REQUEST_CREATE_CUSTOM_STAGE](state) {
    state.isSavingCustomStage = true;
  },
  [types.RECEIVE_CREATE_CUSTOM_STAGE_RESPONSE](state) {
    state.isSavingCustomStage = false;
  },
  [types.REQUEST_UPDATE_STAGE](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_UPDATE_STAGE_RESPONSE](state) {
    state.isLoading = false;
    state.isSavingCustomStage = false;
  },
  [types.REQUEST_REMOVE_STAGE](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_REMOVE_STAGE_RESPONSE](state) {
    state.isLoading = false;
  },
  [types.REQUEST_DURATION_DATA](state) {
    state.isLoadingDurationChart = true;
  },
  [types.RECEIVE_DURATION_DATA_SUCCESS](state, data) {
    state.durationData = data;
    state.isLoadingDurationChart = false;
  },
  [types.RECEIVE_DURATION_DATA_ERROR](state) {
    state.durationData = [];
    state.isLoadingDurationChart = false;
  },
};


