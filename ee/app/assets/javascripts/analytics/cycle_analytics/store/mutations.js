import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import * as types from './mutation_types';
import { transformRawStages, transformRawTasksByTypeData, toggleSelectedLabel } from '../utils';
import { TASKS_BY_TYPE_FILTERS } from '../constants';

export default {
  [types.SET_FEATURE_FLAGS](state, featureFlags) {
    state.featureFlags = featureFlags;
  },
  [types.SET_SELECTED_GROUP](state, group) {
    state.selectedGroup = convertObjectPropsToCamelCase(group, { deep: true });
    state.selectedProjects = [];
  },
  [types.SET_SELECTED_PROJECTS](state, projects) {
    state.selectedProjects = projects;
  },
  [types.SET_SELECTED_STAGE](state, rawData) {
    state.selectedStage = convertObjectPropsToCamelCase(rawData);
  },
  [types.SET_DATE_RANGE](state, { startDate, endDate }) {
    state.startDate = startDate;
    state.endDate = endDate;
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
  [types.REQUEST_TOP_RANKED_GROUP_LABELS](state) {
    state.topRankedLabels = [];
    state.tasksByType = {
      ...state.tasksByType,
      selectedLabelIds: [],
    };
  },
  [types.RECEIVE_TOP_RANKED_GROUP_LABELS_SUCCESS](state, data = []) {
    const { tasksByType } = state;
    state.topRankedLabels = data.map(convertObjectPropsToCamelCase);
    state.tasksByType = {
      ...tasksByType,
      selectedLabelIds: data.map(({ id }) => id),
    };
  },
  [types.RECEIVE_TOP_RANKED_GROUP_LABELS_ERROR](state) {
    const { tasksByType } = state;
    state.topRankedLabels = [];
    state.tasksByType = {
      ...tasksByType,
      selectedLabelIds: [],
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
  [types.SHOW_CUSTOM_STAGE_FORM](state) {
    state.isCreatingCustomStage = true;
    state.isEditingCustomStage = false;
    state.customStageFormInitialData = null;
    state.customStageFormErrors = null;
  },
  [types.SHOW_EDIT_CUSTOM_STAGE_FORM](state, initialData) {
    state.isEditingCustomStage = true;
    state.isCreatingCustomStage = false;
    state.customStageFormInitialData = initialData;
    state.customStageFormErrors = null;
  },
  [types.HIDE_CUSTOM_STAGE_FORM](state) {
    state.isEditingCustomStage = false;
    state.isCreatingCustomStage = false;
    state.customStageFormInitialData = null;
    state.customStageFormErrors = null;
  },
  [types.CLEAR_CUSTOM_STAGE_FORM_ERRORS](state) {
    state.customStageFormErrors = null;
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
    state.stages = transformRawStages(stages);

    state.customStageFormEvents = events.map(ev =>
      convertObjectPropsToCamelCase(ev, { deep: true }),
    );
  },
  [types.REQUEST_TASKS_BY_TYPE_DATA](state) {
    state.isLoadingTasksByTypeChart = true;
  },
  [types.RECEIVE_TASKS_BY_TYPE_DATA_ERROR](state) {
    state.isLoadingTasksByTypeChart = false;
  },
  [types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS](state, data) {
    state.isLoadingTasksByTypeChart = false;
    state.tasksByType = {
      ...state.tasksByType,
      data: transformRawTasksByTypeData(data),
    };
  },
  [types.REQUEST_CREATE_CUSTOM_STAGE](state) {
    state.isSavingCustomStage = true;
    state.customStageFormErrors = {};
  },
  [types.RECEIVE_CREATE_CUSTOM_STAGE_ERROR](state, { errors = null } = {}) {
    state.isSavingCustomStage = false;
    state.customStageFormErrors = convertObjectPropsToCamelCase(errors, { deep: true });
  },
  [types.RECEIVE_CREATE_CUSTOM_STAGE_SUCCESS](state) {
    state.isSavingCustomStage = false;
    state.customStageFormErrors = null;
    state.customStageFormInitialData = null;
  },
  [types.REQUEST_UPDATE_STAGE](state) {
    state.isLoading = true;
    state.isSavingCustomStage = true;
    state.customStageFormErrors = null;
  },
  [types.RECEIVE_UPDATE_STAGE_SUCCESS](state) {
    state.isLoading = false;
    state.isSavingCustomStage = false;
    state.isEditingCustomStage = false;
    state.customStageFormErrors = null;
    state.customStageFormInitialData = null;
  },
  [types.RECEIVE_UPDATE_STAGE_ERROR](state, { errors = null, data } = {}) {
    state.isLoading = false;
    state.isSavingCustomStage = false;
    state.customStageFormErrors = convertObjectPropsToCamelCase(errors, { deep: true });
    state.customStageFormInitialData = convertObjectPropsToCamelCase(data, { deep: true });
  },
  [types.REQUEST_REMOVE_STAGE](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_REMOVE_STAGE_RESPONSE](state) {
    state.isLoading = false;
  },
  [types.SET_TASKS_BY_TYPE_FILTERS](state, { filter, value }) {
    const {
      tasksByType: { selectedLabelIds, ...tasksByTypeRest },
    } = state;
    let updatedFilter = {};
    switch (filter) {
      case TASKS_BY_TYPE_FILTERS.LABEL:
        updatedFilter = {
          selectedLabelIds: toggleSelectedLabel({ selectedLabelIds, value }),
        };
        break;
      case TASKS_BY_TYPE_FILTERS.SUBJECT:
        updatedFilter = { subject: value };
        break;
      default:
        break;
    }
    state.tasksByType = { ...tasksByTypeRest, selectedLabelIds, ...updatedFilter };
  },
  [types.INITIALIZE_CYCLE_ANALYTICS](
    state,
    {
      group: selectedGroup = null,
      createdAfter: startDate = null,
      createdBefore: endDate = null,
      selectedProjects = [],
    } = {},
  ) {
    state.isLoading = true;
    state.selectedGroup = selectedGroup;
    state.selectedProjects = selectedProjects;
    state.startDate = startDate;
    state.endDate = endDate;
  },
  [types.INITIALIZE_CYCLE_ANALYTICS_SUCCESS](state) {
    state.isLoading = false;
  },
  [types.REQUEST_REORDER_STAGE](state) {
    state.isSavingStageOrder = true;
    state.errorSavingStageOrder = false;
  },
  [types.RECEIVE_REORDER_STAGE_SUCCESS](state) {
    state.isSavingStageOrder = false;
    state.errorSavingStageOrder = false;
  },
  [types.RECEIVE_REORDER_STAGE_ERROR](state) {
    state.isSavingStageOrder = false;
    state.errorSavingStageOrder = true;
  },
};
