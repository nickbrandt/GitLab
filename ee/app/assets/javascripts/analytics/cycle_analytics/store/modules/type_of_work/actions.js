import Api from 'ee/api';
import createFlash from '~/flash';
import { __ } from '~/locale';
import * as types from './mutation_types';
import { handleErrorOrRethrow } from '../../../utils';

export const receiveTopRankedGroupLabelsSuccess = ({ commit, dispatch }, data) => {
  commit(types.RECEIVE_TOP_RANKED_GROUP_LABELS_SUCCESS, data);
  dispatch('fetchTasksByTypeData');
};

export const receiveTopRankedGroupLabelsError = ({ commit }, error) => {
  commit(types.RECEIVE_TOP_RANKED_GROUP_LABELS_ERROR, error);
  createFlash(__('There was an error fetching the top labels for the selected group'));
};

export const fetchTopRankedGroupLabels = ({ dispatch, commit, state, rootGetters }) => {
  commit(types.REQUEST_TOP_RANKED_GROUP_LABELS);
  const {
    currentGroupPath,
    cycleAnalyticsRequestParams: {
      project_ids,
      created_after,
      created_before,
      author_username,
      milestone_title,
      assignee_username,
    },
  } = rootGetters;
  const { subject } = state;

  return Api.cycleAnalyticsTopLabels(currentGroupPath, {
    subject,
    project_ids,
    created_after,
    created_before,
    author_username,
    milestone_title,
    assignee_username,
  })
    .then(({ data }) => dispatch('receiveTopRankedGroupLabelsSuccess', data))
    .catch(error =>
      handleErrorOrRethrow({
        error,
        action: () => dispatch('receiveTopRankedGroupLabelsError', error),
      }),
    );
};

export const receiveTasksByTypeDataError = ({ commit }, error) => {
  commit(types.RECEIVE_TASKS_BY_TYPE_DATA_ERROR, error);
  createFlash(__('There was an error fetching data for the tasks by type chart'));
};

export const fetchTasksByTypeData = ({ dispatch, commit, state, rootGetters }) => {
  const { currentGroupPath, cycleAnalyticsRequestParams } = rootGetters;
  const { subject, selectedLabelIds } = state;

  const {
    project_ids,
    created_after,
    created_before,
    author_username,
    milestone_title,
    assignee_username,
  } = cycleAnalyticsRequestParams;

  // ensure we clear any chart data currently in state
  commit(types.REQUEST_TASKS_BY_TYPE_DATA);

  // dont request if we have no labels selected...for now
  if (selectedLabelIds.length) {
    return Api.cycleAnalyticsTasksByType(currentGroupPath, {
      project_ids,
      created_after,
      created_before,
      author_username,
      milestone_title,
      assignee_username,
      subject,
      // NOTE: the type of work module will continute to manage its labels, ignoring the filter bar labels
      // until we resolve: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/34524
      label_ids: selectedLabelIds,
    })
      .then(({ data }) => commit(types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS, data))
      .catch(error => dispatch('receiveTasksByTypeDataError', error));
  }
  return commit(types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS, []);
};

export const setTasksByTypeFilters = ({ dispatch, commit }, data) => {
  commit(types.SET_TASKS_BY_TYPE_FILTERS, data);
  dispatch('fetchTasksByTypeData');
};
