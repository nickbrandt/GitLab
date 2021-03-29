import { getAbsoluteStartDate } from 'ee/oncall_schedules/components/schedule/components/shifts/components/shift_utils';

describe('~ee/oncall_schedules/components/schedule/components/shifts/components/shift_utils.js', () => {
  describe('getAbsoluteStartDate', () => {
    const shift = { startsAt: '2018-01-01T00:00:00.000Z' };
    it('returns a start date in milliseconds', () => {
      expect(getAbsoluteStartDate(shift)).toStrictEqual(1514764800000);
    });
  });
});
