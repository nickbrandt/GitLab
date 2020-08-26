import { deprecatedCreateFlash as createFlash } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import Api from '~/api';
import * as types from './mutation_types';

export const setEndpoints = ({ commit }, { milestonesEndpoint, labelsEndpoint }) => {
  commit(types.SET_MILESTONES_ENDPOINT, milestonesEndpoint);
  commit(types.SET_LABELS_ENDPOINT, labelsEndpoint);
};

export const fetchMilestones = ({ commit, state }, search_title = '') => {
  commit(types.REQUEST_MILESTONES);
  const { milestonesEndpoint } = state;

  return axios
    .get(milestonesEndpoint, { params: { search_title } })
    .then(response => {
      commit(types.RECEIVE_MILESTONES_SUCCESS, response.data);
      return response;
    })
    .catch(({ response }) => {
      const { status } = response;
      commit(types.RECEIVE_MILESTONES_ERROR, status);
      createFlash(__('Failed to load milestones. Please try again.'));
    });
};

export const fetchLabels = ({ commit, state }, search = '') => {
  commit(types.REQUEST_LABELS);

  return axios
    .get(state.labelsEndpoint, { params: { search } })
    .then(response => {
      commit(types.RECEIVE_LABELS_SUCCESS, response.data);
      return response;
    })
    .catch(({ response }) => {
      const { status } = response;
      commit(types.RECEIVE_LABELS_ERROR, status);
      createFlash(__('Failed to load labels. Please try again.'));
    });
};

const fetchUser = ({ commit, endpoint, query, action, errorMessage }) => {
  commit(`REQUEST_${action}`);

  return Api.groupMembers(endpoint, { query })
    .then(response => {
      commit(`RECEIVE_${action}_SUCCESS`, response.data);
      return response;
    })
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

export const setFilters = ({ commit, dispatch }, filters) => {
  commit(types.SET_SELECTED_FILTERS, filters);

  return dispatch('setFilters', filters, { root: true });
};

export const initialize = ({ commit }, initialFilters) => {
  commit(types.SET_SELECTED_FILTERS, initialFilters);
};
