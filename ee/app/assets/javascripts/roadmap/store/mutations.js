import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_DATA](state, data) {
    Object.assign(state, { ...data });
  },

  [types.SET_EPICS](state, epics) {
    state.epics = epics;
  },

  [types.SET_WINDOW_RESIZE_IN_PROGRESS](state, inProgress) {
    state.windowResizeInProgress = inProgress;
  },

  [types.UPDATE_EPIC_IDS](state, epicId) {
    state.epicIds.push(epicId);
  },

  [types.REQUEST_EPICS](state) {
    state.epicsFetchInProgress = true;
  },
  [types.REQUEST_EPICS_FOR_TIMEFRAME](state) {
    state.epicsFetchForTimeframeInProgress = true;
  },
  [types.RECEIVE_EPICS_SUCCESS](state, epics) {
    state.epicsFetchResultEmpty = epics.length === 0;

    if (!state.epicsFetchResultEmpty) {
      state.epics = epics;
    }

    state.epicsFetchInProgress = false;
  },
  [types.RECEIVE_EPICS_FOR_TIMEFRAME_SUCCESS](state, epics) {
    state.epics = epics;
    state.epicsFetchForTimeframeInProgress = false;
  },
  [types.RECEIVE_EPICS_FAILURE](state) {
    state.epicsFetchInProgress = false;
    state.epicsFetchForTimeframeInProgress = false;
    state.epicsFetchFailure = true;
  },

  [types.PREPEND_TIMEFRAME](state, extendedTimeframe) {
    state.extendedTimeframe = extendedTimeframe;
    state.timeframe.unshift(...extendedTimeframe);
  },
  [types.APPEND_TIMEFRAME](state, extendedTimeframe) {
    state.extendedTimeframe = extendedTimeframe;
    state.timeframe.push(...extendedTimeframe);
  },

  [types.SET_BUFFER_SIZE](state, bufferSize) {
    state.bufferSize = bufferSize;
  },
};
