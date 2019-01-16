import createFlash from '~/flash';
import _ from 'underscore';
import { __ } from '~/locale';
import Api from 'ee/api';
import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';
import { mapApprovalRulesResponse } from '../../../mappers';

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

export const requestRules = ({ commit }) => {
  commit(types.SET_LOADING, true);
};

export const receiveRulesSuccess = ({ commit }, rules) => {
  commit(types.SET_LOADING, false);
  commit(types.SET_RULES, rules);
};

export const receiveRulesError = () => {
  createFlash(__('An error occurred fetching the approval rules.'));
};

export const fetchRules = ({ rootState, dispatch }) => {
  dispatch('requestRules');

  const { mrId } = rootState.settings;
  const async = mrId ? dispatch('fetchMergeRequestRules') : dispatch('fetchProjectRules');

  return async
    .then(rules => dispatch('receiveRulesSuccess', rules))
    .catch(() => dispatch('receiveRulesError'));
};

export const fetchProjectRules = ({ rootState }) => {
  const { projectId } = rootState.settings;

  // These will be `new` MR rules so we pull `id` out of the reponse and set it to `sourceId`
  return Api.getProjectApprovalRules(projectId)
    .then(response => mapApprovalRulesResponse(response.data))
    .then(({ rules }) => rules.map(({ id, ...rule }) => ({ ...rule, sourceId: id })));
};

export const fetchMergeRequestRules = ({ rootState }) => {
  const { mrRulesPath } = rootState.settings;

  return axios
    .get(mrRulesPath)
    .then(response => mapApprovalRulesResponse(response.data))
    .then(({ rules }) => rules.filter(x => !x.isCodeOwner));
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
