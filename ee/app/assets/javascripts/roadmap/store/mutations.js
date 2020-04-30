import Vue from 'vue';

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
    Object.keys(state.childrenEpics).forEach(id => {
      Vue.set(state.childrenFlags, id, {
        itemChildrenFetchInProgress: false,
      });
    });
  },

  [types.REQUEST_CHILDREN_EPICS](state, { parentItemId }) {
    state.childrenFlags[parentItemId].itemChildrenFetchInProgress = true;
  },
  [types.RECEIVE_CHILDREN_SUCCESS](state, { parentItemId, children }) {
    Vue.set(state.childrenEpics, parentItemId, children);
    state.childrenFlags[parentItemId].itemChildrenFetchInProgress = false;
  },

  [types.INIT_EPIC_CHILDREN_FLAGS](state, { epics }) {
    epics.forEach(item => {
      Vue.set(state.childrenFlags, item.id, {
        itemExpanded: false,
        itemChildrenFetchInProgress: false,
      });
    });
  },

  [types.EXPAND_EPIC](state, { parentItemId }) {
    state.childrenFlags[parentItemId].itemExpanded = true;
  },
  [types.COLLAPSE_EPIC](state, { parentItemId }) {
    state.childrenFlags[parentItemId].itemExpanded = false;
  },

  [types.PREPEND_TIMEFRAME](state, extendedTimeframe) {
    state.extendedTimeframe = extendedTimeframe;
    state.timeframe.unshift(...extendedTimeframe);
  },
  [types.APPEND_TIMEFRAME](state, extendedTimeframe) {
    state.extendedTimeframe = extendedTimeframe;
    state.timeframe.push(...extendedTimeframe);
  },

  [types.SET_MILESTONES](state, milestones) {
    state.milestones = milestones;
  },
  [types.UPDATE_MILESTONE_IDS](state, milestoneIds) {
    state.milestoneIds.push(...milestoneIds);
  },
  [types.REQUEST_MILESTONES](state) {
    state.milestonesFetchInProgress = true;
  },
  [types.RECEIVE_MILESTONES_SUCCESS](state, milestones) {
    state.milestonesFetchInProgress = false;
    state.milestonesFetchResultEmpty = milestones.length === 0;

    if (!state.milestonesFetchResultEmpty) {
      state.milestones = milestones;
    }
  },
  [types.RECEIVE_MILESTONES_FAILURE](state) {
    state.milestonesFetchInProgress = false;
    state.milestonesFetchFailure = true;
  },

  [types.SET_BUFFER_SIZE](state, bufferSize) {
    state.bufferSize = bufferSize;
  },
};
