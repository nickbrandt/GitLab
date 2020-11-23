import Api from 'ee/api';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { __, sprintf } from '~/locale';
import httpStatus from '~/lib/utils/http_status';
import * as types from './mutation_types';
import { checkForDataError, flashErrorIfStatusNotOk, isStageNameExistsError } from '../../../utils';

export const setSelectedStage = ({ commit }, stage) => commit(types.SET_SELECTED_STAGE, stage);
export const setDefaultSelectedStage = ({ dispatch, rootGetters }) => {
  const { activeStages = [] } = rootGetters;
  if (activeStages?.length) {
    const [firstActiveStage] = activeStages;
    return Promise.all([
      dispatch('setSelectedStage', firstActiveStage),
      dispatch('fetchStageData', firstActiveStage.slug),
    ]);
  }

  createFlash(__('There was an error while fetching value stream analytics data.'));
  return Promise.resolve();
};

export const requestStageMedianValues = ({ commit }) => commit(types.REQUEST_STAGE_MEDIANS);

export const receiveStageMedianValuesError = ({ commit }, error) => {
  commit(types.RECEIVE_STAGE_MEDIANS_ERROR, error);
  createFlash(__('There was an error fetching median data for stages'));
};

const fetchStageMedian = ({ groupId, valueStreamId, stageId, params }) =>
  Api.cycleAnalyticsStageMedian({ groupId, valueStreamId, stageId, params }).then(({ data }) => {
    return {
      id: stageId,
      ...(data?.error
        ? {
            error: data.error,
            value: null,
          }
        : data),
    };
  });

export const fetchStageMedianValues = ({ dispatch, commit, rootGetters }) => {
  const {
    currentGroupPath,
    cycleAnalyticsRequestParams,
    activeStages,
    currentValueStreamId,
  } = rootGetters;
  const stageIds = activeStages.map(s => s.slug);

  dispatch('requestStageMedianValues');
  return Promise.all(
    stageIds.map(stageId =>
      fetchStageMedian({
        groupId: currentGroupPath,
        valueStreamId: currentValueStreamId,
        stageId,
        params: cycleAnalyticsRequestParams,
      }),
    ),
  )
    .then(data => commit(types.RECEIVE_STAGE_MEDIANS_SUCCESS, data))
    .catch(error => dispatch('receiveStageMedianValuesError', error));
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

export const fetchStageData = ({ dispatch, rootGetters }, stageId) => {
  const { cycleAnalyticsRequestParams = {}, currentValueStreamId, currentGroupPath } = rootGetters;
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

export const updateStage = ({ dispatch, rootGetters }, { id, ...params }) => {
  const { currentGroupPath, currentValueStreamId } = rootGetters;

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

export const removeStage = ({ dispatch, rootGetters }, stageId) => {
  const { currentGroupPath, currentValueStreamId } = rootGetters;
  dispatch('requestRemoveStage');

  return Api.cycleAnalyticsRemoveStage({
    groupId: currentGroupPath,
    valueStreamId: currentValueStreamId,
    stageId,
  })
    .then(() => dispatch('receiveRemoveStageSuccess'))
    .catch(error => dispatch('receiveRemoveStageError', error));
};
