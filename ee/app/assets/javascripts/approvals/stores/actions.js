import createFlash from '~/flash';
import { __ } from '~/locale';
import Api from 'ee/api';
import * as types from './mutation_types';
import { mapApprovalRuleRequest, mapApprovalRulesResponse } from '../mappers';

const DEFAULT_SETTINGS = {
  canEdit: true,
};

export const setSettings = ({ commit }, settings) => {
  commit(types.SET_SETTINGS, {
    ...DEFAULT_SETTINGS,
    ...settings,
  });
};

export const requestRules = ({ commit }) => {
  commit(types.SET_LOADING, true);
};

export const receiveRulesSuccess = ({ commit }, { rules }) => {
  commit(types.SET_RULES, rules);
  commit(types.SET_LOADING, false);
};

export const receiveRulesError = () => {
  createFlash(__('An error occurred fetching the approval rules.'));
};

export const fetchRules = ({ state, dispatch }) => {
  if (state.isLoading) {
    return Promise.resolve();
  }

  const { projectId } = state.settings;

  dispatch('requestRules');

  return Api.getProjectApprovalRules(projectId)
    .then(response => dispatch('receiveRulesSuccess', mapApprovalRulesResponse(response.data)))
    .catch(() => dispatch('receiveRulesError'));
};

export const postRuleSuccess = ({ dispatch }) => {
  dispatch('createModal/close');
  dispatch('fetchRules');
};

export const postRuleError = () => {
  createFlash(__('An error occurred while updating approvers'));
};

export const postRule = ({ state, dispatch }, rule) => {
  const { projectId } = state.settings;

  return Api.postProjectApprovalRule(projectId, mapApprovalRuleRequest(rule))
    .then(() => dispatch('postRuleSuccess'))
    .catch(() => dispatch('postRuleError'));
};

export const putRule = ({ state, dispatch }, { id, ...newRule }) => {
  const { projectId } = state.settings;

  return Api.putProjectApprovalRule(projectId, id, mapApprovalRuleRequest(newRule))
    .then(() => dispatch('postRuleSuccess'))
    .catch(() => dispatch('postRuleError'));
};

export const deleteRuleSuccess = ({ dispatch }) => {
  dispatch('deleteModal/close');
  dispatch('fetchRules');
};

export const deleteRuleError = () => {
  createFlash(__('An error occurred while deleting the approvers group'));
};

export const deleteRule = ({ state, dispatch }, id) => {
  const { projectId } = state.settings;

  return Api.deleteProjectApprovalRule(projectId, id)
    .then(() => dispatch('deleteRuleSuccess'))
    .catch(() => dispatch('deleteRuleError'));
};
