import {
  getProjectValueStreamStages,
  getProjectValueStreams,
  getProjectValueStreamMetrics,
  getValueStreamStageMedian,
  getValueStreamStagesAndEvents,
} from '~/api/analytics_api';
import createFlash from '~/flash';
import { __ } from '~/locale';
import { DEFAULT_VALUE_STREAM } from '../constants';
import * as types from './mutation_types';

export const setSelectedValueStream = ({ commit, dispatch }, valueStream) => {
  commit(types.SET_SELECTED_VALUE_STREAM, valueStream);
  return Promise.all([dispatch('fetchValueStreamStages'), dispatch('fetchCycleAnalyticsData')]);
};

export const fetchValueStreamStages = ({ commit, state }) => {
  const {
    endpoints: { fullPath },
    selectedValueStream: { id },
  } = state;
  commit(types.REQUEST_VALUE_STREAM_STAGES);

  return getProjectValueStreamStages(fullPath, id)
    .then(({ data }) => commit(types.RECEIVE_VALUE_STREAM_STAGES_SUCCESS, data))
    .catch(({ response: { status } }) => {
      commit(types.RECEIVE_VALUE_STREAM_STAGES_ERROR, status);
    });
};

export const receiveValueStreamsSuccess = ({ commit, dispatch }, data = []) => {
  commit(types.RECEIVE_VALUE_STREAMS_SUCCESS, data);
  if (data.length) {
    const [firstStream] = data;
    return dispatch('setSelectedValueStream', firstStream);
  }
  return dispatch('setSelectedValueStream', DEFAULT_VALUE_STREAM);
};

export const fetchValueStreams = ({ commit, dispatch, state }) => {
  const {
    endpoints: { fullPath },
    features: { cycleAnalyticsForGroups },
  } = state;
  commit(types.REQUEST_VALUE_STREAMS);

  const stageRequests = ['setSelectedStage'];
  if (cycleAnalyticsForGroups) {
    stageRequests.push('fetchStageMedians');
  }

  return getProjectValueStreams(fullPath)
    .then(({ data }) => dispatch('receiveValueStreamsSuccess', data))
    .then(() => Promise.all(stageRequests.map((r) => dispatch(r))))
    .catch(({ response: { status } }) => {
      commit(types.RECEIVE_VALUE_STREAMS_ERROR, status);
    });
};
export const fetchCycleAnalyticsData = ({
  state: {
    endpoints: { requestPath },
  },
  getters: { legacyFilterParams },
  commit,
}) => {
  commit(types.REQUEST_CYCLE_ANALYTICS_DATA);

  return getProjectValueStreamMetrics(requestPath, legacyFilterParams)
    .then(({ data }) => commit(types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS, data))
    .catch(() => {
      commit(types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR);
      createFlash({
        message: __('There was an error while fetching value stream summary data.'),
      });
    });
};

export const fetchStageData = ({ getters: { requestParams, filterParams }, commit }) => {
  commit(types.REQUEST_STAGE_DATA);

  return getValueStreamStagesAndEvents({ ...requestParams, params: filterParams })
    .then(({ data }) => {
      // when there's a query timeout, the request succeeds but the error is encoded in the response data
      if (data?.error) {
        commit(types.RECEIVE_STAGE_DATA_ERROR, data.error);
      } else {
        commit(types.RECEIVE_STAGE_DATA_SUCCESS, data);
      }
    })
    .catch(() => commit(types.RECEIVE_STAGE_DATA_ERROR));
};

const getStageMedians = ({ stageId, vsaParams, filterParams = {} }) => {
  return getValueStreamStageMedian({ ...vsaParams, stageId }, filterParams).then(({ data }) => ({
    id: stageId,
    value: data?.value || null,
  }));
};

export const fetchStageMedians = ({
  state: { stages },
  getters: { requestParams: vsaParams, filterParams },
  commit,
}) => {
  commit(types.REQUEST_STAGE_MEDIANS);
  return Promise.all(
    stages.map(({ id: stageId }) =>
      getStageMedians({
        vsaParams,
        stageId,
        filterParams,
      }),
    ),
  )
    .then((data) => commit(types.RECEIVE_STAGE_MEDIANS_SUCCESS, data))
    .catch((error) => {
      commit(types.RECEIVE_STAGE_MEDIANS_ERROR, error);
      createFlash({
        message: __('There was an error fetching median data for stages'),
      });
    });
};

export const setSelectedStage = ({ dispatch, commit, state: { stages } }, selectedStage = null) => {
  const stage = selectedStage || stages[0];
  commit(types.SET_SELECTED_STAGE, stage);
  return dispatch('fetchStageData');
};

export const setLoading = ({ commit }, value) => commit(types.SET_LOADING, value);

const refetchStageData = (dispatch) => {
  return Promise.resolve()
    .then(() => dispatch('setLoading', true))
    .then(() => Promise.all([dispatch('fetchCycleAnalyticsData'), dispatch('fetchStageData')]))
    .finally(() => dispatch('setLoading', false));
};

export const setFilters = ({ dispatch }) => refetchStageData(dispatch);

export const setDateRange = ({ dispatch, commit }, daysInPast) => {
  commit(types.SET_DATE_RANGE, daysInPast);
  return refetchStageData(dispatch);
};

const appendExtension = (path) => (path.indexOf('.') > -1 ? path : `${path}.json`);

export const setPaths = ({ dispatch }, options) => {
  const { groupPath, milestonesPath = '', labelsPath = '' } = options;

  return dispatch('filters/setEndpoints', {
    labelsEndpoint: appendExtension(labelsPath),
    milestonesEndpoint: appendExtension(milestonesPath),
    groupEndpoint: groupPath,
  });
};

export const initializeVsa = ({ commit, dispatch }, initialData = {}) => {
  commit(types.INITIALIZE_VSA, initialData);

  const { endpoints } = initialData;
  dispatch('setPaths', endpoints);

  return Promise.resolve()
    .then(() => dispatch('setLoading', true))
    .then(() => dispatch('fetchValueStreams'))
    .finally(() => dispatch('setLoading', false));
};
