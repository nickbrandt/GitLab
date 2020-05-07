import Api from 'ee/api';
import createFlash from '~/flash';
import { __, sprintf } from '~/locale';
import httpStatus from '~/lib/utils/http_status';
import * as types from './mutation_types';
import { removeFlash } from '../../../utils';

const isStageNameExistsError = ({ status, errors }) => {
  const ERROR_NAME_RESERVED = 'is reserved';
  if (status === httpStatus.UNPROCESSABLE_ENTITY) {
    if (errors?.name?.includes(ERROR_NAME_RESERVED)) return true;
  }
  return false;
};

export const setStageEvents = ({ commit }, data) => commit(types.SET_STAGE_EVENTS, data);
export const setStageFormErrors = ({ commit }, errors) =>
  commit(types.SET_STAGE_FORM_ERRORS, errors);

export const hideForm = ({ commit }) => {
  commit(types.HIDE_FORM);
  removeFlash();
};

export const showCreateForm = ({ commit }) => {
  commit(types.SHOW_CREATE_FORM);
  removeFlash();
};

export const showEditForm = ({ commit, dispatch }, selectedStage = {}) => {
  commit(types.SET_FORM_INITIAL_DATA, selectedStage);
  commit(types.SHOW_EDIT_FORM);
  dispatch('setSelectedStage', selectedStage, { root: true });
  removeFlash();
};

export const clearFormErrors = ({ commit }) => {
  commit(types.CLEAR_FORM_ERRORS);
  removeFlash();
};

export const requestCreateStage = ({ commit }) => commit(types.REQUEST_CREATE_STAGE);
export const receiveCreateStageSuccess = ({ commit, dispatch }, { data: { title } }) => {
  commit(types.RECEIVE_CREATE_STAGE_SUCCESS);
  createFlash(sprintf(__(`Your custom stage '%{title}' was created`), { title }), 'notice');

  return Promise.resolve()
    .then(() => dispatch('fetchGroupStagesAndEvents', null, { root: true }))
    .catch(() => {
      createFlash(__('There was a problem refreshing the data, please try again'));
    });
};

export const receiveCreateStageError = (
  { commit, dispatch },
  { status = 400, errors = {}, data = {} } = {},
) => {
  commit(types.RECEIVE_CREATE_STAGE_ERROR);
  const { name = null } = data;
  const flashMessage =
    name && isStageNameExistsError({ status, errors })
      ? sprintf(__(`'%{name}' stage already exists`), { name })
      : __('There was a problem saving your custom stage, please try again');

  createFlash(flashMessage);
  return dispatch('setStageFormErrors', errors);
};

export const createStage = ({ dispatch, rootState }, data) => {
  const {
    selectedGroup: { fullPath },
  } = rootState;

  dispatch('requestCreateStage');

  return Api.cycleAnalyticsCreateStage(fullPath, data)
    .then(response => {
      const { status, data: responseData } = response;
      return dispatch('receiveCreateStageSuccess', { status, data: responseData });
    })
    .catch(({ response } = {}) => {
      const { data: { message, errors } = null, status = 400 } = response;

      dispatch('receiveCreateStageError', { data, message, errors, status });
    });
};
