import * as getters from 'ee/onboarding/onboarding_helper/store/getters';
import createStore from 'ee/onboarding/onboarding_helper/store/state';
import { mockTourData } from '../mock_data';

describe('User onboarding store getters', () => {
  let localState;

  beforeEach(() => {
    localState = createStore();
    localState.projectFullPath = 'http://gitlab-org/gitlab-test';
    localState.tourData = mockTourData;
    localState.tourKey = 1;
    localState.url = 'http://gitlab-org/gitlab-test/foo/bar';
  });

  describe('stepIndex', () => {
    it('returns the current step index if the url matches the data at a given tour key', () => {
      expect(getters.stepIndex(localState)).toBe(1);
    });

    it('returns null if there is no tour data', () => {
      localState.tourData = [];

      expect(getters.stepIndex(localState)).toBe(null);
    });

    it('returns null if there is no tour key', () => {
      localState.tourKey = null;

      expect(getters.stepIndex(localState)).toBe(null);
    });

    it("returns null if the url doesn't match any data at a given tour key", () => {
      localState.url = 'http://not-matching/url';

      expect(getters.stepIndex(localState)).toBe(null);
    });

    it("returns null if the url doesn't match any data due to a different project full path", () => {
      localState.projectFullPath = 'http://my-path/does/not/match';

      expect(getters.stepIndex(localState)).toBe(null);
    });
  });

  describe('stepContent', () => {
    it('returns the correct step content for the active tour step', () => {
      const tourKey = 1;
      const stepIndex = 1;
      const localGetters = {
        stepIndex,
      };

      expect(getters.stepContent(localState, localGetters)).toBe(mockTourData[tourKey][stepIndex]);
    });

    it('returns null if there is no tour data', () => {
      localState.tourData = [];
      const localGetters = {
        stepIndex: 1,
      };

      expect(getters.stepContent(localState, localGetters)).toBe(null);
    });

    it('returns null if there is no step index', () => {
      const localGetters = {
        stepIndex: null,
      };

      expect(getters.stepContent(localState, localGetters)).toBe(null);
    });
  });

  describe('helpContent', () => {
    it('returns the help content for a given index', () => {
      const helpContentIndex = 0;
      const stepContent = {
        getHelpContent: () => [
          {
            text: 'foo',
            buttons: [{ text: 'button', btnClass: 'btn-primary' }],
          },
        ],
      };
      const localGetters = {
        stepContent,
      };
      localState.helpContentIndex = helpContentIndex;

      expect(getters.helpContent(localState, localGetters)).toEqual(
        stepContent.getHelpContent()[helpContentIndex],
      );
    });

    it('displays the project name in the help content text', () => {
      const helpContentIndex = 0;
      const stepContent = {
        getHelpContent: ({ projectName }) => [
          {
            text: `This is the ${projectName}`,
            buttons: [{ text: 'button', btnClass: 'btn-primary' }],
          },
        ],
      };
      const localGetters = {
        stepContent,
      };
      localState.helpContentIndex = helpContentIndex;
      localState.projectName = 'Mock Project';

      const helpContent = getters.helpContent(localState, localGetters);

      expect(helpContent.text).toBe('This is the Mock Project');
    });

    it('returns null if there is no step content', () => {
      const localGetters = {
        stepContent: null,
      };
      localState.helpContentIndex = 0;

      expect(getters.helpContent(localState, localGetters)).toBe(null);
    });

    it('returns null if there is no getHelpContent property on the step content', () => {
      const stepContent = {
        getHelpContent: null,
      };
      const localGetters = {
        stepContent,
      };

      expect(getters.helpContent(localState, localGetters)).toBe(null);
    });
  });

  describe('totalTourPartSteps', () => {
    it('returns the correct number of total tour steps for the tour with key "1"', () => {
      expect(getters.totalTourPartSteps(localState)).toBe(3);
    });

    it('returns 0 if there is no tour data', () => {
      localState.tourData = [];

      expect(getters.totalTourPartSteps(localState)).toBe(0);
    });

    it('returns 0 if there is no tour key', () => {
      localState.tourKey = null;

      expect(getters.totalTourPartSteps(localState)).toBe(0);
    });

    it('returns 0 if there is no data at a given tour key', () => {
      localState.tourKey = 10;

      expect(getters.totalTourPartSteps(localState)).toBe(0);
    });
  });

  describe('percentageCompleted', () => {
    it('returns the percentage completed for the current step', () => {
      localState.lastStepIndex = 1;

      expect(getters.percentageCompleted(localState)).toBe(33);
    });

    it('returns the 0 if there is no step index', () => {
      const localGetters = {
        stepIndex: null,
      };

      expect(getters.percentageCompleted(localState, localGetters)).toBe(0);
    });

    it('returns the 0 if there is no data for a given step index', () => {
      const localGetters = {
        stepIndex: 10,
      };

      expect(getters.percentageCompleted(localState, localGetters)).toBe(0);
    });
  });

  describe('actionPopover', () => {
    it("returns the step content's action popover if the step content exists", () => {
      const stepContent = {
        actionPopover: {
          selector: '.popover-selector',
          text: 'Some action popover content',
        },
      };
      const localGetters = {
        stepContent,
      };

      expect(getters.actionPopover(localState, localGetters)).toEqual(stepContent.actionPopover);
    });

    it('returns null if there is no step content', () => {
      const localGetters = {
        stepContent: null,
      };

      expect(getters.actionPopover(localState, localGetters)).toBeNull();
    });
  });
});
