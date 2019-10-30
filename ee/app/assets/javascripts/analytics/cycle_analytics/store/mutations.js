import { dasherize } from '~/lib/utils/text_utility';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import * as types from './mutation_types';
import { EMPTY_STAGE_TEXT } from '../constants';

export default {
  [types.SET_CYCLE_ANALYTICS_DATA_ENDPOINT](state, groupPath) {
    state.endpoints.cycleAnalyticsData = `/groups/${groupPath}/-/cycle_analytics`;
  },
  [types.SET_STAGE_DATA_ENDPOINT](state, stageSlug) {
    state.endpoints.stageData = `${state.endpoints.cycleAnalyticsData}/events/${stageSlug}.json`;
  },
  [types.SET_SELECTED_GROUP](state, group) {
    state.selectedGroup = convertObjectPropsToCamelCase(group, { deep: true });
    state.selectedProjectIds = [];
  },
  [types.SET_SELECTED_PROJECTS](state, projectIds) {
    state.selectedProjectIds = projectIds;
  },
  [types.SET_SELECTED_STAGE_NAME](state, stageName) {
    state.selectedStageName = stageName;
  },
  [types.SET_DATE_RANGE](state, { startDate, endDate }) {
    state.startDate = startDate;
    state.endDate = endDate;
  },
  [types.REQUEST_CYCLE_ANALYTICS_DATA](state) {
    state.isLoading = true;
    state.isAddingCustomStage = false;
  },
  [types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS](state, data) {
    state.summary = data.summary.map(item => ({
      ...item,
      value: item.value || '-',
    }));

    state.stages = data.stats.map(item => {
      const slug = dasherize(item.name.toLowerCase());
      return {
        ...item,
        isUserAllowed: data.permissions[slug],
        emptyStageText: EMPTY_STAGE_TEXT[slug],
        slug,
      };
    });

    if (state.stages.length) {
      const { name } = state.stages[0];
      state.selectedStageName = name;
    }

    state.errorCode = null;
    state.isLoading = false;
  },
  [types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR](state, errCode) {
    state.errorCode = errCode;
    state.isLoading = false;
  },
  [types.REQUEST_STAGE_DATA](state) {
    state.isLoadingStage = true;
  },
  [types.RECEIVE_STAGE_DATA_SUCCESS](state, data = {}) {
    const { events = [] } = data;
    state.currentStageEvents = events.map(({ name = '', ...rest }) =>
      convertObjectPropsToCamelCase({ title: name, ...rest }, { deep: true }),
    );
    state.isEmptyStage = state.currentStageEvents.length === 0;
    state.isLoadingStage = false;
  },
  [types.RECEIVE_STAGE_DATA_ERROR](state) {
    state.isEmptyStage = true;
    state.isLoadingStage = false;
  },
  [types.REQUEST_GROUP_LABELS](state) {
    state.labels = [];
  },
  [types.RECEIVE_GROUP_LABELS_SUCCESS](state, data = []) {
    state.labels = data.map(convertObjectPropsToCamelCase);
  },
  [types.RECEIVE_GROUP_LABELS_ERROR](state) {
    state.labels = [];
  },
  [types.HIDE_CUSTOM_STAGE_FORM](state) {
    state.isAddingCustomStage = false;
  },
  [types.SHOW_CUSTOM_STAGE_FORM](state) {
    state.isAddingCustomStage = true;
  },
};
