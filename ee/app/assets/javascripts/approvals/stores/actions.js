import createFlash from '~/flash';
import { __ } from '~/locale';
import * as types from './mutation_types';
import service from '../services/approvals_service_stub';

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
    return;
  }

  dispatch('requestRules');

  service
    .getProjectApprovalRules()
    .then(response => dispatch('receiveRulesSuccess', response.data))
    .catch(() => dispatch('receiveRulesError'));
};
