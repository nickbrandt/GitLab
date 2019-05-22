import * as getters from 'ee/dependencies/store/getters';
import { REPORT_STATUS } from 'ee/dependencies/store/constants';

describe('Dependencies getters', () => {
  const testReportStatusGetter = (getterName, reportStatus) => {
    describe(getterName, () => {
      it('returns the correct boolean value', () => {
        expect(
          getters[getterName]({
            reportInfo: {
              status: reportStatus,
            },
          }),
        ).toBe(true);

        expect(
          getters[getterName]({
            reportInfo: {
              status: 'foo',
            },
          }),
        ).toBe(false);
      });
    });
  };

  testReportStatusGetter('jobNotSetUp', REPORT_STATUS.jobNotSetUp);
  testReportStatusGetter('jobFailed', REPORT_STATUS.jobFailed);
  testReportStatusGetter('isIncomplete', REPORT_STATUS.incomplete);
});
