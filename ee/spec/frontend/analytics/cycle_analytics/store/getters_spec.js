import * as getters from 'ee/analytics/cycle_analytics/store/getters';
import {
  allowedStages as stages,
  startDate,
  endDate,
  transformedDurationData,
  durationChartPlottableData,
} from '../mock_data';

let state = null;
const selectedProjectIds = [5, 8, 11];

describe('Cycle analytics getters', () => {
  describe('with default state', () => {
    beforeEach(() => {
      state = {
        stages: [],
        selectedStageId: null,
      };
    });

    afterEach(() => {
      state = null;
    });

    describe('currentStage', () => {
      it('will return null', () => {
        expect(getters.currentStage(state)).toEqual(null);
      });
    });

    describe('defaultStage', () => {
      it('will return null', () => {
        expect(getters.defaultStage(state)).toEqual(null);
      });
    });
  });

  describe('with a set of stages', () => {
    beforeEach(() => {
      state = {
        stages,
        selectedStageId: null,
      };
    });

    afterEach(() => {
      state = null;
    });

    describe('currentStage', () => {
      it('will return null', () => {
        expect(getters.currentStage(state)).toEqual(null);
      });
    });

    describe('defaultStage', () => {
      it('will return the first stage', () => {
        expect(getters.defaultStage(state)).toEqual(stages[0]);
      });
    });
  });

  describe('with a set of stages and a stage selected', () => {
    beforeEach(() => {
      state = {
        stages,
        selectedStageId: stages[2].id,
      };
    });

    afterEach(() => {
      state = null;
    });

    describe('currentStage', () => {
      it('will return null', () => {
        expect(getters.currentStage(state)).toEqual(stages[2]);
      });
    });
  });

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
        selectedProjectIds,
      };
    });

    it.each`
      param               | value
      ${'created_after'}  | ${'2018-12-15'}
      ${'created_before'} | ${'2019-01-14'}
      ${'project_ids'}    | ${[5, 8, 11]}
    `('should return the $param with value $value', ({ param, value }) => {
      expect(getters.cycleAnalyticsRequestParams(state)).toMatchObject({ [param]: value });
    });
  });

  describe('durationChartPlottableData', () => {
    it('returns plottable data for selected stages', () => {
      const stateWithDurationData = {
        startDate,
        endDate,
        durationData: transformedDurationData,
      };

      expect(getters.durationChartPlottableData(stateWithDurationData)).toEqual(
        durationChartPlottableData,
      );
    });

    it('returns null if there is no plottable data for the selected stages', () => {
      const stateWithDurationData = {
        startDate,
        endDate,
        durationData: [],
      };

      expect(getters.durationChartPlottableData(stateWithDurationData)).toBeNull();
    });
  });
});
