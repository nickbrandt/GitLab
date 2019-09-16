import createState from 'ee/analytics/productivity_analytics/store/modules/charts/state';
import * as getters from 'ee/analytics/productivity_analytics/store/modules/charts/getters';
import {
  chartKeys,
  columnHighlightStyle,
  maxColumnChartItemsPerPage,
} from 'ee/analytics/productivity_analytics/constants';
import { mockHistogramData } from '../../../mock_data';

describe('Productivity analytics chart getters', () => {
  let state;

  const groupNamespace = 'gitlab-org';
  const projectPath = 'gitlab-org/gitlab-test';

  beforeEach(() => {
    state = createState();
  });

  describe('chartLoading', () => {
    it('returns true', () => {
      state.charts[chartKeys.main].isLoading = true;

      const result = getters.chartLoading(state)(chartKeys.main);

      expect(result).toBe(true);
    });
  });

  describe('getChartData', () => {
    it("parses the chart's data and adds a color property to selected items", () => {
      const chartKey = chartKeys.main;
      state.charts[chartKey] = {
        data: {
          '1': 32,
          '5': 17,
        },
        selected: ['5'],
      };

      const chartData = {
        full: [
          { value: ['1', 32], itemStyle: {} },
          { value: ['5', 17], itemStyle: columnHighlightStyle },
        ],
      };

      expect(getters.getChartData(state)(chartKey)).toEqual(chartData);
    });
  });

  describe('getMetricDropdownLabel', () => {
    it('returns the correct label for the "time_to_last_commit" metric', () => {
      state.charts[chartKeys.timeBasedHistogram].params = {
        metricType: 'time_to_last_commit',
      };

      expect(getters.getMetricDropdownLabel(state)(chartKeys.timeBasedHistogram)).toBe(
        'Time from first comment to last commit',
      );
    });
  });

  describe('getFilterParams', () => {
    const rootGetters = {};

    rootGetters['filters/getCommonFilterParams'] = {
      group_id: groupNamespace,
      project_id: projectPath,
    };

    describe('main chart', () => {
      it('returns the correct params object', () => {
        const expected = {
          group_id: groupNamespace,
          project_id: projectPath,
          chart_type: state.charts[chartKeys.main].params.chartType,
        };

        expect(getters.getFilterParams(state, null, null, rootGetters)(chartKeys.main)).toEqual(
          expected,
        );
      });
    });

    describe('timeBasedHistogram charts', () => {
      const chartKey = chartKeys.timeBasedHistogram;

      describe('main chart has selected items', () => {
        it('returns the params object including "days_to_merge"', () => {
          state.charts = {
            [chartKeys.main]: {
              selected: ['5'],
            },
            [chartKeys.timeBasedHistogram]: {
              params: {
                chartType: 'histogram',
              },
            },
          };

          const expected = {
            group_id: groupNamespace,
            project_id: projectPath,
            chart_type: state.charts[chartKey].params.chartType,
            days_to_merge: ['5'],
          };

          expect(getters.getFilterParams(state, null, null, rootGetters)(chartKey)).toEqual(
            expected,
          );
        });
      });

      describe('chart has a metricType', () => {
        it('returns the params object including metric_type', () => {
          state.charts = {
            [chartKeys.main]: {
              selected: [],
            },
            [chartKeys.timeBasedHistogram]: {
              params: {
                chartType: 'histogram',
                metricType: 'time_to_first_comment',
              },
            },
          };

          const expected = {
            group_id: groupNamespace,
            project_id: projectPath,
            chart_type: state.charts[chartKey].params.chartType,
            days_to_merge: [],
            metric_type: 'time_to_first_comment',
          };

          expect(getters.getFilterParams(state, null, null, rootGetters)(chartKey)).toEqual(
            expected,
          );
        });
      });
    });
  });

  describe('getColumnChartDatazoomOption', () => {
    const chartKey = chartKeys.main;

    describe(`data exceeds threshold of ${maxColumnChartItemsPerPage[chartKey]} items`, () => {
      it('returns a dataZoom property and computes the end interval correctly', () => {
        state.charts[chartKey].data = mockHistogramData;

        const intervalEnd = 98;

        const expected = {
          dataZoom: [
            {
              type: 'slider',
              bottom: 10,
              start: 0,
              end: intervalEnd,
            },
            {
              type: 'inside',
              start: 0,
              end: intervalEnd,
            },
          ],
        };

        expect(getters.getColumnChartDatazoomOption(state)(chartKeys.main)).toEqual(expected);
      });
    });

    describe(`does not exceed threshold of ${maxColumnChartItemsPerPage[chartKey]} items`, () => {
      it('returns an empty dataZoom property', () => {
        state.charts[chartKey].data = { '1': 1, '2': 2, '3': 3 };

        expect(getters.getColumnChartDatazoomOption(state)(chartKeys.main)).toEqual({});
      });
    });
  });
});
