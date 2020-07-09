import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import Api from '~/api';
import * as types from './mutation_types';

const appendExtension = path => (path.indexOf('.') > -1 ? path : `${path}.json`);

// TODO: After we remove instance VSA we can rely on the paths from the BE
// https://gitlab.com/gitlab-org/gitlab/-/issues/223735
export const setPaths = ({ commit }, { groupPath = '', milestonesPath = '', labelsPath = '' }) => {
  const ms = milestonesPath || `/groups/${groupPath}/-/milestones`;
  const ls = labelsPath || `/groups/${groupPath}/-/labels`;
  commit(types.SET_MILESTONES_PATH, appendExtension(ms));
  commit(types.SET_LABELS_PATH, appendExtension(ls));
};

export const fetchMilestones = ({ commit, state }, search_title = '') => {
  commit(types.REQUEST_MILESTONES);
  const { milestonesPath } = state;

  return axios
    .get(milestonesPath, { params: { search_title } })
    .then(({ data }) => commit(types.RECEIVE_MILESTONES_SUCCESS, data))
    .catch(({ response }) => {
      const { status } = response;
      commit(types.RECEIVE_MILESTONES_ERROR, status);
      createFlash(__('Failed to load milestones. Please try again.'));
    });
};

export const fetchLabels = ({ commit, state }, search = '') => {
  commit(types.REQUEST_LABELS);

  return axios
    .get(state.labelsPath, { params: { search } })
    .then(({ data }) => commit(types.RECEIVE_LABELS_SUCCESS, data))
    .catch(({ response }) => {
      const { status } = response;
      commit(types.RECEIVE_LABELS_ERROR, status);
      createFlash(__('Failed to load labels. Please try again.'));
    });
};

const fetchUser = ({ commit, endpoint, query, action, errorMessage }) => {
  commit(`REQUEST_${action}`);

  return Api.groupMembers(endpoint, { query })
    .then(({ data }) => commit(`RECEIVE_${action}_SUCCESS`, data))
    .catch(({ response }) => {
      const { status } = response;
      commit(`RECEIVE_${action}_ERROR`, status);
      createFlash(errorMessage);
    });
};

export const fetchAuthors = ({ commit, rootGetters }, query = '') => {
  const { currentGroupParentPath } = rootGetters;
  return fetchUser({
    commit,
    query,
    endpoint: currentGroupParentPath,
    action: 'AUTHORS',
    errorMessage: __('Failed to load authors. Please try again.'),
  });
};

export const fetchAssignees = ({ commit, rootGetters }, query = '') => {
  const { currentGroupParentPath } = rootGetters;
  return fetchUser({
    commit,
    query,
    endpoint: currentGroupParentPath,
    action: 'ASSIGNEES',
    errorMessage: __('Failed to load assignees. Please try again.'),
  });
};

export const setFilters = ({ dispatch }, nextFilters) =>
  dispatch('setSelectedFilters', nextFilters, { root: true });

export const initialize = ({ dispatch, commit }, initialFilters) => {
  commit(types.INITIALIZE, initialFilters);
  return dispatch('setPaths', initialFilters).then(() => dispatch('setFilters', initialFilters));
};
