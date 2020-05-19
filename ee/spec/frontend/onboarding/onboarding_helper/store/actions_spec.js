import Cookies from 'js-cookie';
import testAction from 'helpers/vuex_action_helper';
import createState from 'ee/onboarding/onboarding_helper/store/state';
import * as types from 'ee/onboarding/onboarding_helper/store/mutation_types';
import {
  setInitialData,
  setTourKey,
  setLastStepIndex,
  setHelpContentIndex,
  switchTourPart,
  setTourFeedback,
  setDntExitTour,
  setExitTour,
  setDismissed,
} from 'ee/onboarding/onboarding_helper/store/actions';
import { ONBOARDING_DISMISSED_COOKIE_NAME } from 'ee/onboarding/constants';
import onboardingUtils from 'ee/onboarding/utils';
import mockData from '../mock_data';

describe('User onboarding helper store actions', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('setInitialData', () => {
    it(`commits ${types.SET_INITIAL_DATA} mutation`, done => {
      const initialData = mockData;

      testAction(
        setInitialData,
        initialData,
        state,
        [{ type: types.SET_INITIAL_DATA, payload: initialData }],
        [],
        done,
      );
    });
  });

  describe('setTourKey', () => {
    beforeEach(() => {
      jest.spyOn(onboardingUtils, 'updateLocalStorage');
    });

    it(`commits ${types.SET_TOUR_KEY} mutation`, done => {
      const tourKey = 2;

      testAction(
        setTourKey,
        tourKey,
        state,
        [{ type: types.SET_TOUR_KEY, payload: tourKey }],
        [],
        done,
      );
    });

    it('updates localStorage with the tourKey', () => {
      const tourKey = 2;

      setTourKey({ commit() {} }, tourKey);

      expect(onboardingUtils.updateLocalStorage).toHaveBeenCalledWith({ tourKey });
    });
  });

  describe('setLastStepIndex', () => {
    beforeEach(() => {
      jest.spyOn(onboardingUtils, 'updateLocalStorage');
    });

    it(`commits ${types.SET_LAST_STEP_INDEX} mutation`, done => {
      const lastStepIndex = 1;

      testAction(
        setLastStepIndex,
        lastStepIndex,
        state,
        [{ type: types.SET_LAST_STEP_INDEX, payload: lastStepIndex }],
        [],
        done,
      );
    });

    it('updates localStorage with the lastStepIndex', () => {
      const lastStepIndex = 1;

      setLastStepIndex({ commit() {} }, lastStepIndex);

      expect(onboardingUtils.updateLocalStorage).toHaveBeenCalledWith({ lastStepIndex });
    });
  });

  describe('setHelpContentIndex', () => {
    it(`commits ${types.SET_HELP_CONTENT_INDEX} mutation`, done => {
      const helpContentIndex = 1;

      testAction(
        setHelpContentIndex,
        helpContentIndex,
        state,
        [{ type: types.SET_HELP_CONTENT_INDEX, payload: helpContentIndex }],
        [],
        done,
      );
    });
  });

  describe('switchTourPart', () => {
    it('should dispatch setTourKey, setLastStepIndex and', done => {
      const nextPart = 2;

      testAction(
        switchTourPart,
        nextPart,
        state,
        [],
        [
          { type: 'setTourKey', payload: nextPart },
          { type: 'setLastStepIndex', payload: 0 },
          { type: 'setHelpContentIndex', payload: 0 },
        ],
        done,
      );
    });
  });

  describe('setExitTour', () => {
    it(`commits ${types.SET_EXIT_TOUR} mutation`, done => {
      const exitTour = true;

      testAction(
        setExitTour,
        exitTour,
        state,
        [{ type: types.SET_EXIT_TOUR, payload: exitTour }],
        [],
        done,
      );
    });
  });

  describe('setTourFeedback', () => {
    it(`commits ${types.SET_FEEDBACK} mutation`, done => {
      const tourFeedback = true;

      testAction(
        setTourFeedback,
        tourFeedback,
        state,
        [{ type: types.SET_FEEDBACK, payload: tourFeedback }],
        [],
        done,
      );
    });
  });

  describe('setDntExitTour', () => {
    it(`commits ${types.SET_DNT_EXIT_TOUR} mutation`, done => {
      const dntExitTour = true;

      testAction(
        setDntExitTour,
        dntExitTour,
        state,
        [{ type: types.SET_DNT_EXIT_TOUR, payload: dntExitTour }],
        [],
        done,
      );
    });
  });

  describe('setDismissed', () => {
    it(`commits ${types.SET_DISMISSED} mutation`, done => {
      const dismissed = true;

      testAction(
        setDismissed,
        dismissed,
        state,
        [{ type: types.SET_DISMISSED, payload: dismissed }],
        [],
        () => {
          setImmediate(() => {
            expect(Cookies.get(ONBOARDING_DISMISSED_COOKIE_NAME)).toEqual(`${dismissed}`);
            done();
          });
        },
      );
    });
  });
});
