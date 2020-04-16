import * as getters from 'ee/analytics/cycle_analytics/store/modules/duration_chart/getters';
import {
  startDate,
  endDate,
  transformedDurationData,
  transformedDurationMedianData,
  durationChartPlottableData,
  durationChartPlottableMedianData,
} from '../../../mock_data';

const rootState = {
  startDate,
  endDate,
};

describe('DurationChart getters', () => {
  describe('durationChartPlottableData', () => {
    it('returns plottable data for selected stages', () => {
      const stateWithDurationData = {
        durationData: transformedDurationData,
      };

      expect(getters.durationChartPlottableData(stateWithDurationData, getters, rootState)).toEqual(
        durationChartPlottableData,
      );
    });

    it('returns an empty array if there is no plottable data for the selected stages', () => {
      const stateWithDurationData = {
        durationData: [],
      };

      expect(getters.durationChartPlottableData(stateWithDurationData, getters, rootState)).toEqual(
        [],
      );
    });
  });

  describe('durationChartPlottableMedianData', () => {
    it('returns plottable median data for selected stages', () => {
      const stateWithDurationMedianData = {
        durationMedianData: transformedDurationMedianData,
      };

      expect(
        getters.durationChartMedianData(stateWithDurationMedianData, getters, rootState),
      ).toEqual(durationChartPlottableMedianData);
    });

    it('returns an empty array if there is no plottable median data for the selected stages', () => {
      const stateWithDurationMedianData = {
        startDate,
        endDate,
        durationMedianData: [],
      };

      expect(
        getters.durationChartMedianData(stateWithDurationMedianData, getters, rootState),
      ).toEqual([]);
    });
  });
});
