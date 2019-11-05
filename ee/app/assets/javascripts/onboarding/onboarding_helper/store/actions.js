import Cookies from 'js-cookie';
import * as types from './mutation_types';
import { ONBOARDING_DISMISSED_COOKIE_NAME } from '../../constants';
import onboardingUtils from '../../utils';

export const setInitialData = ({ commit }, data) => {
  commit(types.SET_INITIAL_DATA, data);
};

export const setTourKey = ({ commit }, tourKey) => {
  commit(types.SET_TOUR_KEY, tourKey);

  onboardingUtils.updateLocalStorage({ tourKey });
};

export const setLastStepIndex = ({ commit }, lastStepIndex) => {
  commit(types.SET_LAST_STEP_INDEX, lastStepIndex);

  onboardingUtils.updateLocalStorage({ lastStepIndex });
};

export const setHelpContentIndex = ({ commit }, helpContentIndex) => {
  commit(types.SET_HELP_CONTENT_INDEX, helpContentIndex);
};

export const switchTourPart = ({ dispatch }, tourKey) => {
  dispatch('setTourKey', tourKey);
  dispatch('setLastStepIndex', 0);
  dispatch('setHelpContentIndex', 0);
};

export const setTourFeedback = ({ commit }, tourFeedback) => {
  commit(types.SET_FEEDBACK, tourFeedback);
};

export const setExitTour = ({ commit }, exitTour) => {
  commit(types.SET_EXIT_TOUR, exitTour);
};

export const setDntExitTour = ({ commit }, dntExitTour) => {
  commit(types.SET_DNT_EXIT_TOUR, dntExitTour);
};

export const setDismissed = ({ commit }, dismissed) => {
  commit(types.SET_DISMISSED, dismissed);

  Cookies.set(ONBOARDING_DISMISSED_COOKIE_NAME, dismissed);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
