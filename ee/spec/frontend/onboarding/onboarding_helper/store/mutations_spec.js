import createState from 'ee/onboarding/onboarding_helper/store/state';
import mutations from 'ee/onboarding/onboarding_helper/store/mutations';
import * as types from 'ee/onboarding/onboarding_helper/store/mutation_types';
import { mockTourData } from '../mock_data';

describe('User onboarding helper store mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('SET_INITIAL_DATA', () => {
    it('sets all inital data', () => {
      const initialData = {
        url: 'http://gitlab-org/gitlab-test/foo',
        projectFullPath: 'http://gitlab-org/gitlab-test',
        projectName: 'Mock Project',
        tourData: mockTourData,
        tourKey: 1,
        helpContentIndex: 0,
        lastStepIndex: -1,
        dismissed: false,
        createdProjectPath: '',
        exitTour: false,
        tourFeedback: false,
        dntExitTour: false,
      };

      mutations[types.SET_INITIAL_DATA](state, initialData);

      expect(state).toEqual(initialData);
    });
  });

  describe('SET_TOUR_KEY', () => {
    it('sets the tour key', () => {
      const tourKey = 2;
      mutations[types.SET_TOUR_KEY](state, tourKey);

      expect(state.tourKey).toEqual(tourKey);
    });
  });

  describe('SET_LAST_STEP_INDEX', () => {
    it('sets the last step index', () => {
      const lastStepIndex = 1;
      mutations[types.SET_LAST_STEP_INDEX](state, lastStepIndex);

      expect(state.lastStepIndex).toEqual(lastStepIndex);
    });
  });

  describe('SET_HELP_CONTENT_INDEX', () => {
    it('sets the help content index', () => {
      const helpContentIndex = 1;
      mutations[types.SET_HELP_CONTENT_INDEX](state, helpContentIndex);

      expect(state.helpContentIndex).toEqual(helpContentIndex);
    });
  });

  describe('SET_EXIT_TOUR', () => {
    it('sets the exitTour property to true', () => {
      mutations[types.SET_EXIT_TOUR](state, true);

      expect(state.exitTour).toBeTruthy();
    });
  });

  describe('SET_FEEDBACK', () => {
    it('sets the tourFeedback property to true', () => {
      mutations[types.SET_FEEDBACK](state, true);

      expect(state.tourFeedback).toBeTruthy();
    });
  });

  describe('SET_DNT_EXIT_TOUR', () => {
    it('sets the dntExitTour property to true', () => {
      mutations[types.SET_DNT_EXIT_TOUR](state, true);

      expect(state.dntExitTour).toBeTruthy();
    });
  });

  describe('SET_DISMISSED', () => {
    it('sets the dismissed property to true', () => {
      mutations[types.SET_DISMISSED](state, true);

      expect(state.dismissed).toBeTruthy();
    });
  });
});
