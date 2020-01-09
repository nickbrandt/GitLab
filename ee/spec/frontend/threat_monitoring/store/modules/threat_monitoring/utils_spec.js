import {
  getTimeWindowConfig,
  getTimeWindowParams,
} from 'ee/threat_monitoring/store/modules/threat_monitoring/utils';
import { DEFAULT_TIME_WINDOW, TIME_WINDOWS } from 'ee/threat_monitoring/constants';

describe('threatMonitoring module utils', () => {
  describe('getTimeWindowConfig', () => {
    it('gives the correct config for a valid time window', () => {
      Object.entries(TIME_WINDOWS).forEach(([timeWindow, expectedConfig]) => {
        expect(getTimeWindowConfig(timeWindow)).toBe(expectedConfig);
      });
    });

    it('gives the default name for an invalid time window', () => {
      expect(getTimeWindowConfig('foo')).toBe(TIME_WINDOWS[DEFAULT_TIME_WINDOW]);
    });
  });

  describe('getTimeWindowParams', () => {
    const mockTimestamp = new Date(2020, 0, 1, 10).getTime();

    it.each`
      timeWindow           | expectedFrom                  | interval
      ${'thirtyMinutes'}   | ${'2020-01-01T09:30:00.000Z'} | ${'minute'}
      ${'oneHour'}         | ${'2020-01-01T09:00:00.000Z'} | ${'minute'}
      ${'twentyFourHours'} | ${'2019-12-31T10:00:00.000Z'} | ${'hour'}
      ${'sevenDays'}       | ${'2019-12-25T10:00:00.000Z'} | ${'hour'}
      ${'thirtyDays'}      | ${'2019-12-02T10:00:00.000Z'} | ${'day'}
      ${'foo'}             | ${'2019-12-02T10:00:00.000Z'} | ${'day'}
    `(
      'returns the expected params given "$timeWindow"',
      ({ timeWindow, expectedFrom, interval }) => {
        expect(getTimeWindowParams(timeWindow, mockTimestamp)).toEqual({
          from: expectedFrom,
          to: '2020-01-01T10:00:00.000Z',
          interval,
        });
      },
    );
  });
});
