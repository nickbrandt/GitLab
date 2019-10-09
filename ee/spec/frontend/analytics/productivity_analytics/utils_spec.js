import {
  getLabelsEndpoint,
  getMilestonesEndpoint,
  initDateArray,
  transformScatterData,
  getScatterPlotData,
  getScatterPlotDataNew,
  getMedianLineData,
  getMedianLineDataNew,
} from 'ee/analytics/productivity_analytics/utils';

import { mockScatterplotData } from './mock_data';

describe('Productivity Analytics utils', () => {
  const namespacePath = 'gitlab-org';
  const projectWithNamespace = 'gitlab-org/gitlab-test';

  describe('getLabelsEndpoint', () => {
    it('returns the group labels path when no project is given', () => {
      expect(getLabelsEndpoint(namespacePath)).toBe('/groups/gitlab-org/-/labels');
    });

    it('returns the project labels path when a project is given', () => {
      expect(getLabelsEndpoint(namespacePath, projectWithNamespace)).toBe(
        '/gitlab-org/gitlab-test/-/labels',
      );
    });
  });

  describe('getMilestonesEndpoint', () => {
    it('returns the group milestone path when no project is given', () => {
      expect(getMilestonesEndpoint(namespacePath)).toBe('/groups/gitlab-org/-/milestones');
    });

    it('returns the project milestone path when a project is given', () => {
      expect(getMilestonesEndpoint(namespacePath, projectWithNamespace)).toBe(
        '/gitlab-org/gitlab-test/-/milestones',
      );
    });
  });

  describe('initDateArray', () => {
    it('creates a two-dimensional array with 3 empty arrays for startDate=2019-09-01 and endDate=2019-09-03', () => {
      const startDate = new Date('2019-09-01');
      const endDate = new Date('2019-09-03');

      expect(initDateArray(startDate, endDate)).toEqual([[], [], []]);
    });
  });

  describe('transformScatterData', () => {
    it('transforms the raw scatter data into a two-dimensional array and groups by date', () => {
      const startDate = new Date('2019-08-01');
      const endDate = new Date('2019-08-03');
      const data = {
        1: { merged_at: '2019-08-01T11:10:00.000Z', metric: 10 },
        2: { merged_at: '2019-08-01T12:11:00.000Z', metric: 20 },
        3: { merged_at: '2019-08-02T13:13:00.000Z', metric: 30 },
        4: { merged_at: '2019-08-03T14:14:00.000Z', metric: 40 },
      };
      const result = transformScatterData(data, startDate, endDate);
      const expected = [
        [
          { merged_at: '2019-08-01T11:10:00.000Z', metric: 10 },
          { merged_at: '2019-08-01T12:11:00.000Z', metric: 20 },
        ],
        [{ merged_at: '2019-08-02T13:13:00.000Z', metric: 30 }],
        [{ merged_at: '2019-08-03T14:14:00.000Z', metric: 40 }],
      ];
      expect(result).toEqual(expected);
    });
  });

  describe('getScatterPlotData', () => {
    it('filters out data before given "dateInPast", transforms the data and sorts by date ascending', () => {
      const dateInPast = new Date(2019, 7, 9); // '2019-08-09T22:00:00.000Z';
      const result = getScatterPlotData(mockScatterplotData, dateInPast);
      const expected = [
        ['2019-08-09T22:00:00.000Z', 44],
        ['2019-08-10T22:00:00.000Z', 46],
        ['2019-08-11T22:00:00.000Z', 62],
        ['2019-08-12T22:00:00.000Z', 60],
        ['2019-08-13T22:00:00.000Z', 43],
        ['2019-08-14T22:00:00.000Z', 46],
        ['2019-08-15T22:00:00.000Z', 56],
        ['2019-08-16T22:00:00.000Z', 24],
        ['2019-08-17T22:00:00.000Z', 138],
        ['2019-08-18T22:00:00.000Z', 139],
      ];
      expect(result).toEqual(expected);
    });
  });

  describe('getScatterPlotDataNew', () => {
    it('returns a subset of data for the given start and end date and flattens the data', () => {
      const startDate = new Date('2019-08-02');
      const endDate = new Date('2019-08-04');
      const data = [
        [{ merged_at: '2019-08-01T11:00:00.000Z', metric: 10 }],
        [{ merged_at: '2019-08-02T13:00:00.000Z', metric: 30 }],
        [{ merged_at: '2019-08-03T14:00:00.000Z', metric: 40 }],
        [
          { merged_at: '2019-08-04T15:00:00.000Z', metric: 50 },
          { merged_at: '2019-08-04T16:00:00.000Z', metric: 60 },
        ],
      ];
      const result = getScatterPlotDataNew(data, startDate, endDate);
      const expected = [
        ['2019-08-02', 30, '2019-08-02T13:00:00.000Z'],
        ['2019-08-03', 40, '2019-08-03T14:00:00.000Z'],
        ['2019-08-04', 50, '2019-08-04T15:00:00.000Z'],
        ['2019-08-04', 60, '2019-08-04T16:00:00.000Z'],
      ];
      expect(result).toEqual(expected);
    });
  });

  describe('getMedianLineData', () => {
    const daysOffset = 10;

    it(`computes the median for every item in the scatterData array for the past ${daysOffset} days`, () => {
      const scatterData = [
        ['2019-08-16T22:00:00.000Z', 24],
        ['2019-08-17T22:00:00.000Z', 138],
        ['2019-08-18T22:00:00.000Z', 139],
      ];
      const result = getMedianLineData(mockScatterplotData, scatterData, daysOffset);
      const expected = [
        ['2019-08-16T22:00:00.000Z', 51],
        ['2019-08-17T22:00:00.000Z', 51],
        ['2019-08-18T22:00:00.000Z', 56],
      ];
      expect(result).toEqual(expected);
    });
  });

  describe('getMedianLineDataNew', () => {
    const daysOffset = 2;

    it(`computes the median for every date in the data array based on the past ${daysOffset} days`, () => {
      const startDate = new Date('2019-08-04');
      const endDate = new Date('2019-08-06');
      const data = [
        [{ merged_at: '2019-08-01T11:00:00.000Z', metric: 10 }],
        [{ merged_at: '2019-08-02T13:00:00.000Z', metric: 30 }],
        [{ merged_at: '2019-08-03T14:00:00.000Z', metric: 40 }],
        [
          { merged_at: '2019-08-04T15:00:00.000Z', metric: 50 },
          { merged_at: '2019-08-04T16:00:00.000Z', metric: 60 },
        ],
        [{ merged_at: '2019-08-05T17:00:00.000Z', metric: 70 }],
        [{ merged_at: '2019-08-06T18:00:00.000Z', metric: 80 }],
      ];
      const result = getMedianLineDataNew(data, startDate, endDate, daysOffset);
      const expected = [['2019-08-04', 45], ['2019-08-05', 55], ['2019-08-06', 65]];
      expect(result).toEqual(expected);
    });
  });
});
