import _ from 'lodash';
import * as datetimeRange from '~/lib/utils/datetime_range';

const MOCK_NOW = Date.UTC(2020, 0, 23, 20); // 2020-01-23T20:00:00.000Z
const rangeTypes = {
  fixed: [{ startTime: 'exists', endTime: 'exists' }],
  anchored: [{ anchor: 'exists', duration: 'exists' }],
  rolling: [{ duration: 'exists' }],
  open: [{ anchor: 'exists' }],
  invalid: [{ startTime: 'exists' }, { endTime: 'exists' }, {}, { junk: 'exists' }],
};

describe('Date time range utils', () => {
  describe('getRangeType', () => {
    const { getRangeType } = datetimeRange;

    it('it correctly infers the range type from the input object', () => {
      Object.entries(rangeTypes).forEach(([type, examples]) => {
        examples.forEach(example => expect(getRangeType(example)).toEqual(type));
      });
    });
  });

  describe('convertToFixedRange', () => {
    const { convertToFixedRange } = datetimeRange;

    beforeEach(() => {
      Date.now = jest.spyOn(Date, 'now').mockImplementation(() => MOCK_NOW);
    });

    afterEach(() => {
      Date.now.mockRestore();
    });

    describe('When a fixed range is input', () => {
      const defaultFixedRange = {
        startTime: '2020-01-01T00:00:00.000Z',
        endTime: '2020-01-31T23:59:00.000Z',
        label: 'January 2020',
      };

      const mockFixedRange = params => ({ ...defaultFixedRange, ...params });

      it('it converts a fixed range to an equal fixed range', () => {
        const aFixedRange = mockFixedRange();

        expect(convertToFixedRange(aFixedRange)).toEqual({
          startTime: defaultFixedRange.startTime,
          endTime: defaultFixedRange.endTime,
        });
      });

      it('it throws an error when fixed range does not contain an end time', () => {
        const aFixedRangeMissingEnd = _.omit(mockFixedRange(), 'endTime');

        expect(() => convertToFixedRange(aFixedRangeMissingEnd)).toThrow();
      });

      it('it throws an error when fixed range does not contain a start time', () => {
        const aFixedRangeMissingStart = _.omit(mockFixedRange(), 'startTime');

        expect(() => convertToFixedRange(aFixedRangeMissingStart)).toThrow();
      });

      it('it throws an error when the dates cannot be parsed', () => {
        const wrongStart = mockFixedRange({ startTime: 'I_CANNOT_BE_PARSED' });
        const wrongEnd = mockFixedRange({ endTime: 'I_CANNOT_BE_PARSED' });

        expect(() => convertToFixedRange(wrongStart)).toThrow();
        expect(() => convertToFixedRange(wrongEnd)).toThrow();
      });
    });

    describe('When an anchored range is input', () => {
      const defaultAnchoredRange = {
        anchor: '2020-01-01T00:00:00.000Z',
        direction: 'after',
        duration: {
          seconds: 60 * 2,
        },
        label: 'First two minutes of 2020',
      };
      const mockAnchoredRange = params => ({ ...defaultAnchoredRange, ...params });

      it('it converts to a fixed range', () => {
        const anAnchoredRange = mockAnchoredRange();

        expect(convertToFixedRange(anAnchoredRange)).toEqual({
          startTime: '2020-01-01T00:00:00.000Z',
          endTime: '2020-01-01T00:02:00.000Z',
        });
      });

      it('it converts to a fixed range with a `before` direction', () => {
        const anAnchoredRange = mockAnchoredRange({ direction: 'before' });

        expect(convertToFixedRange(anAnchoredRange)).toEqual({
          startTime: '2019-12-31T23:58:00.000Z',
          endTime: '2020-01-01T00:00:00.000Z',
        });
      });

      it('it converts to a fixed range without an explicit direction, defaulting to `before`', () => {
        const anAnchoredRange = _.omit(mockAnchoredRange(), 'direction');

        expect(convertToFixedRange(anAnchoredRange)).toEqual({
          startTime: '2019-12-31T23:58:00.000Z',
          endTime: '2020-01-01T00:00:00.000Z',
        });
      });

      it('it throws an error when the anchor cannot be parsed', () => {
        const wrongAnchor = mockAnchoredRange({ anchor: 'I_CANNOT_BE_PARSED' });

        expect(() => convertToFixedRange(wrongAnchor)).toThrow();
      });
    });

    describe('when a rolling range is input', () => {
      it('it converts to a fixed range', () => {
        const aRollingRange = {
          direction: 'after',
          duration: {
            seconds: 60 * 2,
          },
          label: 'Next 2 minutes',
        };

        expect(convertToFixedRange(aRollingRange)).toEqual({
          startTime: '2020-01-23T20:00:00.000Z',
          endTime: '2020-01-23T20:02:00.000Z',
        });
      });

      it('it converts to a fixed range with an implicit `before` direction', () => {
        const aRollingRangeWithNoDirection = {
          duration: {
            seconds: 60 * 2,
          },
          label: 'Last 2 minutes',
        };

        expect(convertToFixedRange(aRollingRangeWithNoDirection)).toEqual({
          startTime: '2020-01-23T19:58:00.000Z',
          endTime: '2020-01-23T20:00:00.000Z',
        });
      });

      it('it throws an error when the duration is not the right format', () => {
        const wrongDuration = {
          direction: 'before',
          duration: {
            minutes: 2,
          },
          label: 'Last 2 minutes',
        };

        expect(() => convertToFixedRange(wrongDuration)).toThrow();
      });

      it('it throws an error when the duration is not ', () => {
        const wrongAnchor = {
          anchor: 'CAN_T_PARSE_THIS',
          direction: 'after',
          label: '2020 so far',
        };

        expect(() => convertToFixedRange(wrongAnchor)).toThrow();
      });
    });

    describe('when an open range is input', () => {
      it('it converts to a fixed range with an `after` direction', () => {
        const soFar2020 = {
          anchor: '2020-01-01T00:00:00.000Z',
          direction: 'after',
          label: '2020 so far',
        };

        expect(convertToFixedRange(soFar2020)).toEqual({
          startTime: '2020-01-01T00:00:00.000Z',
          endTime: '2020-01-23T20:00:00.000Z',
        });
      });

      it('it converts to a fixed range with the explicit `before` direction', () => {
        const before2020 = {
          anchor: '2020-01-01T00:00:00.000Z',
          direction: 'before',
          label: 'Before 2020',
        };

        expect(convertToFixedRange(before2020)).toEqual({
          startTime: '1970-01-01T00:00:00.000Z',
          endTime: '2020-01-01T00:00:00.000Z',
        });
      });

      it('it converts to a fixed range with the implicit `before` direction', () => {
        const alsoBefore2020 = {
          anchor: '2020-01-01T00:00:00.000Z',
          label: 'Before 2020',
        };

        expect(convertToFixedRange(alsoBefore2020)).toEqual({
          startTime: '1970-01-01T00:00:00.000Z',
          endTime: '2020-01-01T00:00:00.000Z',
        });
      });

      it('it throws an error when the anchor cannot be parsed', () => {
        const wrongAnchor = {
          anchor: 'CAN_T_PARSE_THIS',
          direction: 'after',
          label: '2020 so far',
        };

        expect(() => convertToFixedRange(wrongAnchor)).toThrow();
      });
    });
  });
});
