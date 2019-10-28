import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_DATA](state, payload) {
    Object.assign(state, payload);
  },
  [types.SET_TOUR_KEY](state, payload) {
    state.tourKey = payload;
  },
  [types.SET_LAST_STEP_INDEX](state, payload) {
    state.lastStepIndex = payload;
  },
  [types.SET_HELP_CONTENT_INDEX](state, payload) {
    state.helpContentIndex = payload;
  },
  [types.SET_FEEDBACK](state, payload) {
    state.tourFeedback = payload;
  },
  [types.SET_DNT_EXIT_TOUR](state, payload) {
    state.dntExitTour = payload;
  },
  [types.SET_EXIT_TOUR](state, payload) {
    state.exitTour = payload;
  },
  [types.SET_DISMISSED](state, payload) {
    state.dismissed = payload;
  },
};
