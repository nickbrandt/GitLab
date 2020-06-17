import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import Api from '~/api';
import * as types from './mutation_types';

const appendExtension = path => (path.indexOf('.') > -1 ? path : `${path}.json`);

export const setPaths = ({ commit }, { milestonesPath = '', labelsPath = '' }) => {
  commit(types.SET_MILESTONES_PATH, appendExtension(milestonesPath));
  commit(types.SET_LABELS_PATH, appendExtension(labelsPath));
};

export const fetchTokenData = ({ dispatch }) => {
  return Promise.all([
    dispatch('fetchLabels'),
    dispatch('fetchMilestones'),
    dispatch('fetchAuthors'),
    dispatch('fetchAssignees'),
  ]);
};

export const fetchMilestones = ({ commit, state }) => {
  commit(types.REQUEST_MILESTONES);
  const { milestonesPath } = state;

  return axios
    .get(milestonesPath)
    .then(({ data }) => commit(types.RECEIVE_MILESTONES_SUCCESS, data))
    .catch(({ response }) => {
      const { status } = response;
      commit(types.RECEIVE_MILESTONES_ERROR, status);
      createFlash(__('Failed to load milestones. Please try again.'));
    });
};

export const fetchLabels = ({ commit, state }) => {
  commit(types.REQUEST_LABELS);

  return axios
    .get(state.labelsPath)
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
  const { currentGroupPath } = rootGetters;
  return fetchUser({
    commit,
    query,
    endpoint: currentGroupPath,
    action: 'AUTHORS',
    errorMessage: __('Failed to load authors. Please try again.'),
  });
};

export const fetchAssignees = ({ commit, rootGetters }, query = '') => {
  const { currentGroupPath } = rootGetters;
  return fetchUser({
    commit,
    query,
    endpoint: currentGroupPath,
    action: 'ASSIGNEES',
    errorMessage: __('Failed to load assignees. Please try again.'),
  });
};

export const setFilters = ({ dispatch }, nextFilters) =>
  dispatch('setSelectedFilters', nextFilters, { root: true });

export const initialize = ({ dispatch, commit }, initialFilters) => {
  commit(types.INITIALIZE, initialFilters);
  return Promise.resolve()
    .then(() => dispatch('setPaths', initialFilters))
    .then(() => dispatch('setFilters', initialFilters));
};
