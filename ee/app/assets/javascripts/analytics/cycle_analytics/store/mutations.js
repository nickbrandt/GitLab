import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import * as types from './mutation_types';
import { transformRawStages } from '../utils';

export default {
  [types.SET_CYCLE_ANALYTICS_DATA_ENDPOINT](state, groupPath) {
    // TODO: this endpoint will be removed when the /-/analytics endpoints are ready
    // https://gitlab.com/gitlab-org/gitlab/issues/34751
    state.endpoints.cycleAnalyticsData = `/groups/${groupPath}/-/cycle_analytics`;
    state.endpoints.cycleAnalyticsStagesAndEvents = `/-/analytics/cycle_analytics/stages?group_id=${groupPath}`;
  },
  [types.SET_STAGE_DATA_ENDPOINT](state, stageSlug) {
    // TODO: this endpoint will be replaced with a /-/analytics... endpoint when backend is ready
    // https://gitlab.com/gitlab-org/gitlab/issues/34751
    const { fullPath } = state.selectedGroup;
    state.endpoints.stageData = `/groups/${fullPath}/-/cycle_analytics/events/${stageSlug}.json`;
  },
  [types.SET_SELECTED_GROUP](state, group) {
    state.selectedGroup = convertObjectPropsToCamelCase(group, { deep: true });
    state.selectedProjectIds = [];
  },
  [types.SET_SELECTED_PROJECTS](state, projectIds) {
    state.selectedProjectIds = projectIds;
  },
  [types.SET_SELECTED_STAGE_ID](state, stageId) {
    state.selectedStageId = stageId;
  },
  [types.SET_DATE_RANGE](state, { startDate, endDate }) {
    state.startDate = startDate;
    state.endDate = endDate;
  },
  [types.REQUEST_CYCLE_ANALYTICS_DATA](state) {
    state.isLoading = true;
    state.isAddingCustomStage = false;
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
  [types.RECEIVE_STAGE_DATA_SUCCESS](state, data = {}) {
    const { events = [] } = data;

    state.currentStageEvents = events.map(({ name = '', ...rest }) =>
      convertObjectPropsToCamelCase({ title: name, ...rest }, { deep: true }),
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
  [types.RECEIVE_SUMMARY_DATA_ERROR](state) {
    state.summary = [];
  },
  [types.REQUEST_SUMMARY_DATA](state) {
    state.summary = [];
  },
  [types.RECEIVE_SUMMARY_DATA_SUCCESS](state, data) {
    const { stages } = state;
    const { summary, stats } = data;
    state.summary = summary.map(item => ({
      ...item,
      value: item.value || '-',
    }));

    /*
     * Medians will eventually be fetched from a separate endpoint, which will
     * include the median calculations for the custom stages, for now we will
     * grab the medians from the group level cycle analytics endpoint, which does
     * not include the custom stages
     * https://gitlab.com/gitlab-org/gitlab/issues/34751
     */
    state.stages = stages.map(stage => {
      const stat = stats.find(m => m.name === stage.slug);
      return { ...stage, value: stat ? stat.value : null };
    });
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

    if (state.stages.length) {
      const { id } = state.stages[0];
      state.selectedStageId = id;
    }
  },
};
