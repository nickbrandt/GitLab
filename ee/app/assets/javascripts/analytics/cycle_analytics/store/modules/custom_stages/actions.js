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

export const hideCustomStageForm = ({ commit }) => {
  commit(types.HIDE_CUSTOM_STAGE_FORM);
  removeFlash();
};

export const showCustomStageForm = ({ commit }) => {
  commit(types.SHOW_CUSTOM_STAGE_FORM);
  removeFlash();
};

export const showEditCustomStageForm = ({ commit, dispatch }, selectedStage = {}) => {
  const {
    id = null,
    name = null,
    startEventIdentifier = null,
    startEventLabel: { id: startEventLabelId = null } = {},
    endEventIdentifier = null,
    endEventLabel: { id: endEventLabelId = null } = {},
  } = selectedStage;

  commit(types.SHOW_EDIT_CUSTOM_STAGE_FORM, {
    id,
    name,
    startEventIdentifier,
    startEventLabelId,
    endEventIdentifier,
    endEventLabelId,
  });
  dispatch('setSelectedStage', selectedStage);
  removeFlash();
};

export const clearCustomStageFormErrors = ({ commit }) => {
  commit(types.CLEAR_CUSTOM_STAGE_FORM_ERRORS);
  removeFlash();
};

export const requestCreateCustomStage = ({ commit }) => commit(types.REQUEST_CREATE_CUSTOM_STAGE);
export const receiveCreateCustomStageSuccess = ({ commit, dispatch }, { data: { title } }) => {
  commit(types.RECEIVE_CREATE_CUSTOM_STAGE_SUCCESS);
  createFlash(sprintf(__(`Your custom stage '%{title}' was created`), { title }), 'notice');

  return Promise.resolve()
    .then(() => dispatch('fetchGroupStagesAndEvents'))
    .catch(() => {
      createFlash(__('There was a problem refreshing the data, please try again'));
    });
};

export const receiveCreateCustomStageError = (
  { commit },
  { status = 400, errors = {}, data = {} } = {},
) => {
  commit(types.RECEIVE_CREATE_CUSTOM_STAGE_ERROR, { errors });
  const { name = null } = data;
  const flashMessage =
    name && isStageNameExistsError({ status, errors })
      ? sprintf(__(`'%{name}' stage already exists`), { name })
      : __('There was a problem saving your custom stage, please try again');

  createFlash(flashMessage);
};

export const createCustomStage = ({ dispatch, state }, data) => {
  const {
    selectedGroup: { fullPath },
  } = state;
  dispatch('requestCreateCustomStage');

  return Api.cycleAnalyticsCreateStage(fullPath, data)
    .then(response => {
      const { status, data: responseData } = response;
      return dispatch('receiveCreateCustomStageSuccess', { status, data: responseData });
    })
    .catch(({ response } = {}) => {
      const { data: { message, errors } = null, status = 400 } = response;

      dispatch('receiveCreateCustomStageError', { data, message, errors, status });
    });
};
