import { apiDataToChartSeries, buildNullSeriesForLeadTimeChart } from 'ee/dora/components/util';

const lastWeekData = getJSONFixture(
  'api/dora/metrics/daily_lead_time_for_changes_for_last_week.json',
);

describe('ee/dora/components/util.js', () => {
  describe('apiDataToChartSeries', () => {
    it('transforms the data from the API into data the chart component can use', () => {
      const apiData = [
        // This is the date format we expect from the API
        { value: 5, date: '2015-06-28' },

        // But we should support _any_ date format
        { value: 1, date: '2015-06-28T20:00:00.000-0400' },
        { value: 8, date: '2015-07-01T00:00:00.000Z' },
      ];

      const startDate = new Date(2015, 5, 26, 10);
      const endDate = new Date(2015, 6, 4, 10);
      const chartTitle = 'Chart title';

      const expected = [
        {
          name: chartTitle,
          data: [
            ['Jun 26', 0],
            ['Jun 27', 0],
            ['Jun 28', 5],
            ['Jun 29', 1],
            ['Jun 30', 0],
            ['Jul 1', 8],
            ['Jul 2', 0],
            ['Jul 3', 0],
          ],
        },
      ];

      expect(apiDataToChartSeries(apiData, startDate, endDate, chartTitle)).toEqual(expected);
    });
  });

  describe('buildNullSeriesForLeadTimeChart', () => {
    it('returns series data with the expected styles and text', () => {
      const inputSeries = [
        {
          name: 'Chart title',
          data: [],
        },
      ];

      const expectedSeries = [
        {
          name: 'No merge requests were deployed during this period',
          data: expect.any(Array),
          lineStyle: {
            color: expect.any(String),
            type: 'dashed',
          },
          areaStyle: {
            color: 'none',
          },
          itemStyle: {
            color: expect.any(String),
          },
        },
        {
          name: 'Chart title',
          showAllSymbol: true,
          showSymbol: true,
          symbolSize: 8,
          data: expect.any(Array),
          lineStyle: {
            color: expect.any(String),
          },
          areaStyle: {
            color: expect.any(String),
          },
          itemStyle: {
            color: expect.any(String),
          },
        },
      ];

      expect(buildNullSeriesForLeadTimeChart(inputSeries)).toEqual(expectedSeries);
    });

    describe('series data', () => {
      describe('non-empty series', () => {
        it('returns the provided non-empty series data unmodified as the second series', () => {
          const inputSeries = [
            {
              data: [
                ['Mar 1', 4],
                ['Mar 2', null],
                ['Mar 3', null],
                ['Mar 4', 10],
              ],
            },
          ];

          const actualSeries = buildNullSeriesForLeadTimeChart(inputSeries);

          expect(actualSeries[1]).toMatchObject(inputSeries[0]);
        });
      });

      describe('empty series', () => {
        const compareSeriesData = (inputSeriesData, expectedEmptySeriesData) => {
          const actualEmptySeriesData = buildNullSeriesForLeadTimeChart([
            { data: inputSeriesData },
          ])[0].data;

          expect(actualEmptySeriesData).toEqual(expectedEmptySeriesData);
        };

        describe('when the data contains a gap in the middle of the data set', () => {
          it('builds the "no data" series by linealy interpolating between the provided data points', () => {
            const inputSeriesData = [
              ['Mar 1', 4],
              ['Mar 2', null],
              ['Mar 3', null],
              ['Mar 4', 10],
            ];

            const expectedEmptySeriesData = [
              ['Mar 1', 4],
              ['Mar 2', 6],
              ['Mar 3', 8],
              ['Mar 4', 10],
            ];

            compareSeriesData(inputSeriesData, expectedEmptySeriesData);
          });
        });

        describe('when the data contains a gap at the beginning of the data set', () => {
          it('fills in the gap using the first non-null data point value', () => {
            const inputSeriesData = [
              ['Mar 1', null],
              ['Mar 2', null],
              ['Mar 3', null],
              ['Mar 4', 10],
            ];

            const expectedEmptySeriesData = [
              ['Mar 1', 10],
              ['Mar 2', 10],
              ['Mar 3', 10],
              ['Mar 4', 10],
            ];

            compareSeriesData(inputSeriesData, expectedEmptySeriesData);
          });
        });

        describe('when the data contains a gap at the end of the data set', () => {
          it('fills in the gap using the last non-null data point value', () => {
            const inputSeriesData = [
              ['Mar 1', 10],
              ['Mar 2', null],
              ['Mar 3', null],
              ['Mar 4', null],
            ];

            const expectedEmptySeriesData = [
              ['Mar 1', 10],
              ['Mar 2', 10],
              ['Mar 3', 10],
              ['Mar 4', 10],
            ];

            compareSeriesData(inputSeriesData, expectedEmptySeriesData);
          });
        });

        describe('when the data contains all null values', () => {
          it('fills the empty series with all zeros', () => {
            const inputSeriesData = [
              ['Mar 1', null],
              ['Mar 2', null],
              ['Mar 3', null],
              ['Mar 4', null],
            ];

            const expectedEmptySeriesData = [
              ['Mar 1', 0],
              ['Mar 2', 0],
              ['Mar 3', 0],
              ['Mar 4', 0],
            ];

            compareSeriesData(inputSeriesData, expectedEmptySeriesData);
          });
        });
      });
    });
  });

  describe('lead time data', () => {
    it('returns the correct lead time chart data after all processing of the API response', () => {
      const chartData = buildNullSeriesForLeadTimeChart(
        apiDataToChartSeries(
          lastWeekData,
          new Date(2015, 5, 27, 10),
          new Date(2015, 6, 4, 10),
          'Lead time',
          null,
        ),
      );

      expect(chartData).toMatchSnapshot();
    });
  });
});
