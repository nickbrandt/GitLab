import createFlash from '~/flash';
import { __ } from '~/locale';
import Api from 'ee/api';
import * as types from '../base/mutation_types';
import {
  mapApprovalRuleRequest,
  mapApprovalSettingsResponse,
  mapApprovalFallbackRuleRequest,
} from '../../../mappers';

export const requestRules = ({ commit }) => {
  commit(types.SET_LOADING, true);
};

export const receiveRulesSuccess = ({ commit }, approvalSettings) => {
  commit(types.SET_APPROVAL_SETTINGS, approvalSettings);
  commit(types.SET_LOADING, false);
};

export const receiveRulesError = () => {
  createFlash(__('An error occurred fetching the approval rules.'));
};

export const fetchRules = ({ rootState, dispatch }) => {
  const { projectId } = rootState.settings;

  dispatch('requestRules');

  return Api.getProjectApprovalSettings(projectId)
    .then(response => dispatch('receiveRulesSuccess', mapApprovalSettingsResponse(response.data)))
    .catch(() => dispatch('receiveRulesError'));
};

export const postRuleSuccess = ({ dispatch }) => {
  dispatch('createModal/close');
  dispatch('fetchRules');
};

export const postRuleError = () => {
  createFlash(__('An error occurred while updating approvers'));
};

export const postRule = ({ rootState, dispatch }, rule) => {
  const { projectId } = rootState.settings;

  return Api.postProjectApprovalRule(projectId, mapApprovalRuleRequest(rule))
    .then(() => dispatch('postRuleSuccess'))
    .catch(() => dispatch('postRuleError'));
};

export const putRule = ({ rootState, dispatch }, { id, ...newRule }) => {
  const { projectId } = rootState.settings;

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

export const deleteRule = ({ rootState, dispatch }, id) => {
  const { projectId } = rootState.settings;

  return Api.deleteProjectApprovalRule(projectId, id)
    .then(() => dispatch('deleteRuleSuccess'))
    .catch(() => dispatch('deleteRuleError'));
};

export const putFallbackRuleSuccess = ({ dispatch }) => {
  dispatch('createModal/close');
  dispatch('fetchRules');
};

export const putFallbackRuleError = () => {
  createFlash(__('An error occurred while saving the approval settings'));
};

export const putFallbackRule = ({ rootState, dispatch }, fallback) => {
  const { projectId } = rootState.settings;

  return Api.putProjectApprovalSettings(projectId, mapApprovalFallbackRuleRequest(fallback))
    .then(() => dispatch('putFallbackRuleSuccess'))
    .catch(() => dispatch('putFallbackRuleError'));
};

export const requestEditRule = ({ dispatch }, rule) => {
  dispatch('createModal/open', rule);
};

export const requestDeleteRule = ({ dispatch }, rule) => {
  dispatch('deleteModal/open', rule);
};

export default () => {};
