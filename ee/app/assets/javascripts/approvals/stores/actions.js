import createFlash from '~/flash';
import { __ } from '~/locale';
import * as types from './mutation_types';
import service from '../services/approvals_service_stub';
import { mapApprovalRuleRequest, mapApprovalRulesResponse } from '../mappers';

export const setSettings = ({ commit }, settings) => {
  commit(types.SET_SETTINGS, settings);
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

  dispatch('requestRules');

  return service
    .getProjectApprovalRules()
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

export const postRule = ({ dispatch }, rule) =>
  service
    .postProjectApprovalRule(mapApprovalRuleRequest(rule))
    .then(() => dispatch('postRuleSuccess'))
    .catch(() => dispatch('postRuleError'));

export const putRule = ({ dispatch }, { id, ...newRule }) =>
  service
    .putProjectApprovalRule(id, mapApprovalRuleRequest(newRule))
    .then(() => dispatch('postRuleSuccess'))
    .catch(() => dispatch('postRuleError'));

export const deleteRuleSuccess = ({ dispatch }) => {
  dispatch('deleteModal/close');
  dispatch('fetchRules');
};

export const deleteRuleError = () => {
  createFlash(__('An error occurred while deleting the approvers group'));
};

export const deleteRule = ({ dispatch }, id) =>
  service
    .deleteProjectApprovalRule(id)
    .then(() => dispatch('deleteRuleSuccess'))
    .catch(() => dispatch('deleteRuleError'));
