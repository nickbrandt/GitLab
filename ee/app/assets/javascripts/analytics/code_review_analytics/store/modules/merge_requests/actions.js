import API from 'ee/api';
import * as types from './mutation_types';
import { __ } from '~/locale';
import createFlash from '~/flash';
import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';

export const setProjectId = ({ commit }, projectId) => commit(types.SET_PROJECT_ID, projectId);

export const fetchMergeRequests = ({ commit, state, rootState }) => {
  commit(types.REQUEST_MERGE_REQUESTS);

  const { projectId, pageInfo } = state;

  const { selected: milestoneTitle } = rootState.filters.milestones;
  const { selected: labelNames } = rootState.filters.labels;

  const params = {
    project_id: projectId,
    milestone_title: milestoneTitle?.operator === '=' ? milestoneTitle.value : null,
    label_name: labelNames?.filter(l => l.operator === '=').map(l => l.value),
    'not[label_name]': labelNames?.filter(l => l.operator === '!=').map(l => l.value),
    'not[milestone_title]': milestoneTitle?.operator === '!=' ? milestoneTitle.value : null,
    page: pageInfo.page,
  };

  return API.codeReviewAnalytics(params)
    .then(response => {
      const { headers, data } = response;
      const normalizedHeaders = normalizeHeaders(headers);
      commit(types.RECEIVE_MERGE_REQUESTS_SUCCESS, {
        pageInfo: parseIntPagination(normalizedHeaders),
        mergeRequests: data,
      });
    })
    .catch(({ response }) => {
      const { status } = response;
      commit(types.RECEIVE_MERGE_REQUESTS_ERROR, status);
      createFlash(__('An error occurred while loading merge requests.'));
    });
};

export const setPage = ({ commit }, page) => commit(types.SET_PAGE, page);
