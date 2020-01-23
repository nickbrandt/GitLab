import * as datetimeRange from '~/lib/utils/datetime_range';

const MOCK_NOW = 1579809600000; // 2020-01-23T20:00:00.000Z

describe('Date time range utils', () => {
  beforeAll(() => {
    Date.now = jest.spyOn(Date, 'now').mockImplementation(() => MOCK_NOW);
  });

  afterAll(() => {
    Date.now.mockRestore();
  });

  describe('getTimeRange', () => {
    const { getTimeRange } = datetimeRange;

    it('transforms an absolute time window into a time range', () => {
      const timeWindow = {
        absoluteStart: '2020-01-01T00:00:00.000Z',
        absoluteEnd: '2020-01-31T23:59:00.000Z',
        label: 'January 2020',
      };

      expect(getTimeRange(timeWindow)).toEqual({
        start_time: '2020-01-01T00:00:00.000Z',
        end_time: '2019-12-31T23:58:00.000Z',
      });
    });

    it('transforms an time window with an absolute end and a duration into a time range', () => {
      const timeWindow = {
        absoluteEnd: '2019-12-31T23:58:00.000Z',
        direction: 'before',
        duration: {
          seconds: 120,
        },
        label: 'The last 2 minutes 2019',
      };

      expect(getTimeRange(timeWindow)).toEqual({
        start_time: '2020-01-01T00:00:00.000Z',
        end_time: '2019-12-31T23:58:00.000Z',
      });
    });

    it('transforms an time window with an absolute start and a duration into a time range', () => {
      const timeWindow = {
        absoluteStart: '2020-01-01T00:00:00.000Z',
        duration: {
          seconds: 120,
        },
        label: 'The first 2 minutes of 2020',
      };

      expect(getTimeRange(timeWindow)).toEqual({
        start: '2020-01-01T00:00:00.000Z',
        end: '2020-01-01T00:02:00.000Z',
      });
    });

    it('transforms an time window with an absolute start time', () => {
      const timeWindow = {
        absoluteStart: '2020-01-01T00:00:00.000Z',
        label: 'From 2020 onwards',
      };

      expect(getTimeRange(timeWindow)).toEqual({
        start: '2020-01-01T00:00:00.000Z',
        // end is not defined in the result
      });
    });

    it('transforms a time window with an absolute end time', () => {
      const timeWindow = {
        absoluteEnd: '2020-01-01T00:00:00.000Z',
        label: 'Before 2020',
      };

      expect(getTimeRange(timeWindow)).toEqual({
        // start is not defined in the result
        end: '2020-01-01T00:00:00.000Z',
      });
    });

    it('transforms a time window with a relative start in the past', () => {
      const timeWindow = {
        direction: 'before',
        duration: {
          seconds: 120,
        },
        label: 'The last 2 minutes',
      };

      expect(getTimeRange(timeWindow)).toEqual({
        start: '2020-01-23T20:00:00.000Z',
        end: '2020-01-23T19:58:00.000Z',
      });
    });

    it('transforms a time window with a relative start in the future', () => {
      const timeWindow = {
        duration: {
          seconds: 120,
        },
        label: 'During the next 2 minutes',
      };

      expect(getTimeRange(timeWindow)).toEqual({
        start: '2020-01-23T20:00:00.000Z',
        end: '2020-01-23T20:02:00.000Z',
      });
    });

    // Error cases

    it('throws when a time window `start`, `end` and `duration` are provided', () => {
      const timeWindow = {
        absoluteStart: '2020-01-01T00:00:00.000Z',
        absoluteEnd: '2020-01-02T00:00:00.000Z',
        duration: {
          seconds: 120,
        },
        label: 'During the next 2 minutes',
      };

      expect(getTimeRange(timeWindow)).toThrow();
    });

    it('throws when `duration` is negative', () => {
      const timeWindow = {
        duration: {
          seconds: -1,
        },
        label: 'Invalid range',
      };

      expect(getTimeRange(timeWindow)).toThrow();
    });
  });
});
