import Api from 'ee/api';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { __, sprintf } from '~/locale';
import httpStatus from '~/lib/utils/http_status';
import * as types from './mutation_types';
import { checkForDataError, flashErrorIfStatusNotOk, isStageNameExistsError } from '../../../utils';

export const setSelectedStage = ({ commit }, stage) => commit(types.SET_SELECTED_STAGE, stage);

export const requestReorderStage = ({ commit }) => commit(types.REQUEST_REORDER_STAGE);
export const receiveReorderStageSuccess = ({ commit }) =>
  commit(types.RECEIVE_REORDER_STAGE_SUCCESS);

export const receiveReorderStageError = ({ commit }) => {
  commit(types.RECEIVE_REORDER_STAGE_ERROR);
  createFlash(__('There was an error updating the stage order. Please try reloading the page.'));
};

export const reorderStage = ({ dispatch, rootGetters }, initialData) => {
  dispatch('requestReorderStage');
  const { currentGroupPath, currentValueStreamId } = rootGetters;
  const { id, moveAfterId, moveBeforeId } = initialData;

  const params = moveAfterId ? { move_after_id: moveAfterId } : { move_before_id: moveBeforeId };

  return Api.cycleAnalyticsUpdateStage({
    groupId: currentGroupPath,
    valueStreamId: currentValueStreamId,
    stageId: id,
    data: params,
  })
    .then(({ data }) => dispatch('receiveReorderStageSuccess', data))
    .catch(({ response: { status = httpStatus.BAD_REQUEST, data: responseData } = {} }) =>
      dispatch('receiveReorderStageError', { status, responseData }),
    );
};

export const requestStageData = ({ commit }) => commit(types.REQUEST_STAGE_DATA);
export const receiveStageDataSuccess = ({ commit }, data) => {
  commit(types.RECEIVE_STAGE_DATA_SUCCESS, data);
};

export const receiveStageDataError = ({ commit }, error) => {
  const { message = '' } = error;
  flashErrorIfStatusNotOk({
    error,
    message: __('There was an error fetching data for the selected stage'),
  });
  commit(types.RECEIVE_STAGE_DATA_ERROR, message);
};

export const fetchStageData = ({ dispatch, getters }, stageId) => {
  const { cycleAnalyticsRequestParams = {}, currentValueStreamId, currentGroupPath } = getters;
  dispatch('requestStageData');

  return Api.cycleAnalyticsStageEvents({
    groupId: currentGroupPath,
    valueStreamId: currentValueStreamId,
    stageId,
    params: cycleAnalyticsRequestParams,
  })
    .then(checkForDataError)
    .then(({ data }) => dispatch('receiveStageDataSuccess', data))
    .catch(error => dispatch('receiveStageDataError', error));
};

export const requestUpdateStage = ({ commit }) => commit(types.REQUEST_UPDATE_STAGE);
export const receiveUpdateStageSuccess = ({ commit, dispatch }, updatedData) => {
  commit(types.RECEIVE_UPDATE_STAGE_SUCCESS);
  createFlash(__('Stage data updated'), 'notice');
  return Promise.resolve()
    .then(() => dispatch('fetchGroupStagesAndEvents'))
    .then(() => dispatch('customStages/showEditForm', updatedData))
    .catch(() => {
      createFlash(__('There was a problem refreshing the data, please try again'));
    });
};

export const receiveUpdateStageError = (
  { commit, dispatch },
  { status, responseData: { errors = null } = {}, data = {} },
) => {
  commit(types.RECEIVE_UPDATE_STAGE_ERROR, { errors, data });

  const { name = null } = data;
  const message =
    name && isStageNameExistsError({ status, errors })
      ? sprintf(__(`'%{name}' stage already exists`), { name })
      : __('There was a problem saving your custom stage, please try again');

  createFlash(__(message));
  return dispatch('customStages/setStageFormErrors', errors);
};

export const updateStage = ({ dispatch, getters }, { id, ...params }) => {
  const { currentGroupPath, currentValueStreamId } = getters;

  dispatch('requestUpdateStage');
  dispatch('customStages/setSavingCustomStage');

  return Api.cycleAnalyticsUpdateStage({
    groupId: currentGroupPath,
    valueStreamId: currentValueStreamId,
    stageId: id,
    data: params,
  })
    .then(({ data }) => dispatch('receiveUpdateStageSuccess', data))
    .catch(({ response: { status = httpStatus.BAD_REQUEST, data: responseData } = {} }) =>
      dispatch('receiveUpdateStageError', { status, responseData, data: { id, ...params } }),
    );
};

export const requestRemoveStage = ({ commit }) => commit(types.REQUEST_REMOVE_STAGE);
export const receiveRemoveStageSuccess = ({ commit, dispatch }) => {
  commit(types.RECEIVE_REMOVE_STAGE_RESPONSE);
  createFlash(__('Stage removed'), 'notice');
  return dispatch('fetchCycleAnalyticsData');
};

export const receiveRemoveStageError = ({ commit }) => {
  commit(types.RECEIVE_REMOVE_STAGE_RESPONSE);
  createFlash(__('There was an error removing your custom stage, please try again'));
};

export const removeStage = ({ dispatch, getters }, stageId) => {
  const { currentGroupPath, currentValueStreamId } = getters;
  dispatch('requestRemoveStage');

  return Api.cycleAnalyticsRemoveStage({
    groupId: currentGroupPath,
    valueStreamId: currentValueStreamId,
    stageId,
  })
    .then(() => dispatch('receiveRemoveStageSuccess'))
    .catch(error => dispatch('receiveRemoveStageError', error));
};
