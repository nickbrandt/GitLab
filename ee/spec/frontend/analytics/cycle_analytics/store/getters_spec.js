import * as getters from 'ee/analytics/cycle_analytics/store/getters';
import {
  startDate,
  endDate,
  allowedStages,
  selectedProjects,
  transformedStagePathData,
  issueStage,
  stageMedians,
} from '../mock_data';

let state = null;

describe('Cycle analytics getters', () => {
  describe('hasNoAccessError', () => {
    beforeEach(() => {
      state = {
        errorCode: null,
      };
    });

    it('returns true if "hasError" is set to 403', () => {
      state.errorCode = 403;
      expect(getters.hasNoAccessError(state)).toEqual(true);
    });

    it('returns false if "hasError" is not set to 403', () => {
      expect(getters.hasNoAccessError(state)).toEqual(false);
    });
  });

  describe('selectedProjectIds', () => {
    describe('with selectedProjects set', () => {
      it('returns the ids of each project', () => {
        state = {
          selectedProjects,
        };

        expect(getters.selectedProjectIds(state)).toEqual([1, 2]);
      });
    });

    describe('without selectedProjects set', () => {
      it('will return an empty array', () => {
        state = { selectedProjects: [] };
        expect(getters.selectedProjectIds(state)).toEqual([]);
      });
    });
  });

  describe('currentGroupPath', () => {
    describe('with selectedGroup set', () => {
      it('returns the `fullPath` value of the group', () => {
        const fullPath = 'cool-beans';
        state = {
          selectedGroup: {
            fullPath,
          },
        };

        expect(getters.currentGroupPath(state)).toEqual(fullPath);
      });
    });

    describe('without a selectedGroup set', () => {
      it.each([[''], [{}], [null]])('given %s will return null', value => {
        state = { selectedGroup: value };
        expect(getters.currentGroupPath(state)).toEqual(null);
      });
    });
  });

  describe('cycleAnalyticsRequestParams', () => {
    beforeEach(() => {
      const fullPath = 'cool-beans';
      state = {
        selectedGroup: {
          fullPath,
        },
        startDate,
        endDate,
        selectedProjects,
      };
    });

    it.each`
      param               | value
      ${'created_after'}  | ${'2018-12-15'}
      ${'created_before'} | ${'2019-01-14'}
      ${'project_ids'}    | ${[1, 2]}
    `('should return the $param with value $value', ({ param, value }) => {
      expect(
        getters.cycleAnalyticsRequestParams(state, { selectedProjectIds: [1, 2] }),
      ).toMatchObject({
        [param]: value,
      });
    });
  });

  const hiddenStage = { ...allowedStages[2], hidden: true };
  const givenStages = [allowedStages[0], allowedStages[1], hiddenStage];
  describe.each`
    func              | givenStages    | expectedStages
    ${'hiddenStages'} | ${givenStages} | ${[hiddenStage]}
    ${'activeStages'} | ${givenStages} | ${[allowedStages[0], allowedStages[1]]}
  `('hiddenStages', ({ func, expectedStages, givenStages: stages }) => {
    it(`'${func}' returns ${expectedStages.length} stages`, () => {
      expect(getters[func]({ stages })).toEqual(expectedStages);
    });

    it(`'${func}' returns an empty array if there are no stages`, () => {
      expect(getters[func]({ stages: [] })).toEqual([]);
    });
  });

  describe('enableCustomOrdering', () => {
    describe('with no errors saving the stage order', () => {
      beforeEach(() => {
        state = {
          errorSavingStageOrder: false,
        };
      });

      it('returns true when stages have numeric IDs', () => {
        state.stages = [{ id: 1 }, { id: 2 }];
        expect(getters.enableCustomOrdering(state)).toEqual(true);
      });

      it('returns false when stages have string based IDs', () => {
        state.stages = [{ id: 'one' }, { id: 'two' }];
        expect(getters.enableCustomOrdering(state)).toEqual(false);
      });
    });

    describe('with errors saving the stage order', () => {
      beforeEach(() => {
        state = {
          errorSavingStageOrder: true,
        };
      });

      it('returns false when stages have numeric IDs', () => {
        state.stages = [{ id: 1 }, { id: 2 }];
        expect(getters.enableCustomOrdering(state)).toEqual(false);
      });

      it('returns false when stages have string based IDs', () => {
        state.stages = [{ id: 'one' }, { id: 'two' }];
        expect(getters.enableCustomOrdering(state)).toEqual(false);
      });
    });
  });

  describe.each`
    isEditingCustomStage | isCreatingCustomStage | result
    ${true}              | ${true}               | ${true}
    ${true}              | ${false}              | ${true}
    ${false}             | ${true}               | ${true}
    ${null}              | ${true}               | ${true}
    ${true}              | ${null}               | ${true}
    ${null}              | ${null}               | ${false}
    ${false}             | ${false}              | ${false}
  `('customStageFormActive', ({ isEditingCustomStage, isCreatingCustomStage, result }) => {
    it(`returns ${result} when isEditingCustomStage=${isEditingCustomStage} and isCreatingCustomStage=${isCreatingCustomStage}`, () => {
      const resp = getters.customStageFormActive({ isCreatingCustomStage, isEditingCustomStage });
      expect(resp).toEqual(result);
    });
  });

  describe('pathNavigationData', () => {
    it('returns the transformed data', () => {
      state = {
        stages: allowedStages,
        medians: stageMedians,
        selectedStage: issueStage,
      };

      expect(getters.pathNavigationData(state)).toEqual(transformedStagePathData);
    });
  });
});
