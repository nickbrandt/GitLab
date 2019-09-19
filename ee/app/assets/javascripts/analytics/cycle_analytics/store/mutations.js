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
    state.selectedGroup = group;
    state.selectedProjectIds = [];
  },
  [types.SET_SELECTED_PROJECTS](state, projectIds) {
    state.selectedProjectIds = projectIds;
  },
  [types.SET_SELECTED_TIMEFRAME](state, timeframe) {
    state.dataTimeframe = timeframe;
  },
  [types.SET_SELECTED_STAGE_NAME](state, stageName) {
    state.selectedStageName = stageName;
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
  [types.RECEIVE_STAGE_DATA_SUCCESS](state, data) {
    state.events = data.events.map(({ name = '', ...rest }) =>
      convertObjectPropsToCamelCase({ title: name, ...rest }, { deep: true }),
    );
    state.isEmptyStage = state.events.length === 0;
    state.isLoadingStage = false;
  },
  [types.RECEIVE_STAGE_DATA_ERROR](state) {
    state.isEmptyStage = true;
    state.isLoadingStage = false;
  },
  [types.SHOW_CUSTOM_STAGE_FORM](state) {
    state.isAddingCustomStage = true;
    state.isEmptyStage = false;
    state.isLoadingStage = false;
  },
  [types.HIDE_CUSTOM_STAGE_FORM](state) {
    state.isAddingCustomStage = false;
    state.isEmptyStage = false;
    state.isLoadingStage = false;
  },
};
