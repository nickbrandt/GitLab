import Api from 'ee/api';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { __ } from '~/locale';
import httpStatus from '~/lib/utils/http_status';
import * as types from './mutation_types';
import { checkForDataError, flashErrorIfStatusNotOk } from '../../../utils';

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
