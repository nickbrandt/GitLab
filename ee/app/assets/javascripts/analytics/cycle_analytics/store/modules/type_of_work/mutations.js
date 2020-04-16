import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import * as types from './mutation_types';
import { transformRawTasksByTypeData, toggleSelectedLabel } from '../../../utils';
import { TASKS_BY_TYPE_FILTERS } from '../../../constants';

export default {
  [types.REQUEST_TOP_RANKED_GROUP_LABELS](state) {
    state.isLoadingTasksByTypeChartTopLabels = true;
    state.topRankedLabels = [];
    state.selectedLabelIds = [];
  },
  [types.RECEIVE_TOP_RANKED_GROUP_LABELS_SUCCESS](state, data = []) {
    state.isLoadingTasksByTypeChartTopLabels = false;
    state.topRankedLabels = data.map(convertObjectPropsToCamelCase);
    state.selectedLabelIds = data.map(({ id }) => id);
  },
  [types.RECEIVE_TOP_RANKED_GROUP_LABELS_ERROR](state) {
    state.isLoadingTasksByTypeChartTopLabels = false;
    state.topRankedLabels = [];
    state.selectedLabelIds = [];
  },
  [types.REQUEST_TASKS_BY_TYPE_DATA](state) {
    state.isLoadingTasksByTypeChart = true;
  },
  [types.RECEIVE_TASKS_BY_TYPE_DATA_ERROR](state) {
    state.isLoadingTasksByTypeChart = false;
  },
  [types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS](state, data = []) {
    state.isLoadingTasksByTypeChart = false;
    state.data = transformRawTasksByTypeData(data);
  },
  [types.SET_TASKS_BY_TYPE_FILTERS](state, { filter, value }) {
    const { selectedLabelIds } = state;
    switch (filter) {
      case TASKS_BY_TYPE_FILTERS.LABEL:
        state.selectedLabelIds = toggleSelectedLabel({ selectedLabelIds, value });
        break;
      case TASKS_BY_TYPE_FILTERS.SUBJECT:
        state.subject = value;
        break;
      default:
        break;
    }
  },
};
