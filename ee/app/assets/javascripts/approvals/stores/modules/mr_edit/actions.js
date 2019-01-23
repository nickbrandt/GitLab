import createFlash from '~/flash';
import _ from 'underscore';
import { __ } from '~/locale';
import Api from 'ee/api';
import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';
import { mapApprovalSettingsResponse } from '../../../mappers';

const fetchGroupMembers = id => Api.groupMembers(id).then(response => response.data);

const fetchApprovers = ({ userRecords, groups }) => {
  const groupUsersAsync = Promise.all(groups.map(fetchGroupMembers));

  return groupUsersAsync
    .then(_.flatten)
    .then(groupUsers => groupUsers.concat(userRecords))
    .then(users => _.uniq(users, false, x => x.id));
};

const seedApprovers = rule =>
  rule.groups || rule.userRecords
    ? fetchApprovers(rule).then(approvers => ({
        ...rule,
        approvers,
      }))
    : Promise.resolve(rule);

const seedUsers = ({ userRecords, ...rule }) =>
  userRecords ? { ...rule, users: userRecords } : rule;

const seedGroups = ({ groupRecords, ...rule }) =>
  groupRecords ? { ...rule, groups: groupRecords } : rule;

const seedLocalRule = rule =>
  seedApprovers(rule)
    .then(seedUsers)
    .then(seedGroups);

// If the MR doesn't have custom rules, then we pull `id` out and set it to `sourceId`
const asSourcedRules = rules => rules.map(({ id, ...rule }) => ({ ...rule, sourceId: id }));

export const requestRules = ({ commit }) => {
  commit(types.SET_LOADING, true);
};

export const receiveRulesSuccess = ({ commit }, rules) => {
  commit(types.SET_LOADING, false);
  commit(types.SET_APPROVAL_SETTINGS, rules);
};

export const receiveRulesError = () => {
  createFlash(__('An error occurred fetching the approval rules.'));
};

export const fetchRules = ({ rootState, dispatch }) => {
  dispatch('requestRules');

  const { mrId } = rootState.settings;
  const async = mrId ? dispatch('fetchMergeRequestRules') : dispatch('fetchProjectRules');

  return async
    .then(({ rules, hasCustomRules, ...settings }) => ({
      ...settings,
      rules: hasCustomRules ? rules : asSourcedRules(rules),
    }))
    .then(approvalSettings => dispatch('receiveRulesSuccess', approvalSettings))
    .catch(() => dispatch('receiveRulesError'));
};

export const fetchProjectRules = ({ rootState }) => {
  const { projectId } = rootState.settings;

  return Api.getProjectApprovalSettings(projectId).then(response =>
    mapApprovalSettingsResponse(response.data),
  );
};

export const fetchMergeRequestRules = ({ rootState }) => {
  const { approvalSettingsPath } = rootState.settings;

  return axios
    .get(approvalSettingsPath)
    .then(response => mapApprovalSettingsResponse(response.data))
    .then(data => ({
      ...data,
      rules: data.rules.filter(x => !x.isCodeOwner),
    }));
};

export const postRule = ({ commit, dispatch }, rule) =>
  seedLocalRule(rule)
    .then(newRule => {
      commit(types.POST_RULE, newRule);
      dispatch('createModal/close');
    })
    .catch(e => {
      createFlash(__('An error occurred fetching the approvers for the new rule.'));
      throw e;
    });

export const putRule = ({ commit, dispatch }, rule) =>
  seedLocalRule(rule)
    .then(newRule => {
      commit(types.PUT_RULE, newRule);
      dispatch('createModal/close');
    })
    .catch(e => {
      createFlash(__('An error occurred fetching the approvers for the new rule.'));
      throw e;
    });

export const deleteRule = ({ commit, dispatch }, id) => {
  commit(types.DELETE_RULE, id);
  dispatch('deleteModal/close');
};

export const putFallbackRule = ({ commit, dispatch }, fallback) => {
  commit(types.SET_FALLBACK_RULE, fallback);
  dispatch('createModal/close');
};
