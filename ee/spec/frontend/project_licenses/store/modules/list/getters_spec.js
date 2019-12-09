import * as getters from 'ee/project_licenses/store/modules/list/getters';
import { REPORT_STATUS } from 'ee/project_licenses/store/modules/list/constants';

describe('Licenses getters', () => {
  describe.each`
    getterName       | reportStatus                 | outcome
    ${'isJobSetUp'}  | ${REPORT_STATUS.jobNotSetUp} | ${false}
    ${'isJobSetUp'}  | ${REPORT_STATUS.ok}          | ${true}
    ${'isJobFailed'} | ${REPORT_STATUS.jobFailed}   | ${true}
    ${'isJobFailed'} | ${REPORT_STATUS.noLicenses}  | ${true}
    ${'isJobFailed'} | ${REPORT_STATUS.incomplete}  | ${true}
    ${'isJobFailed'} | ${REPORT_STATUS.ok}          | ${false}
  `('$getterName when report status is $reportStatus', ({ getterName, reportStatus, outcome }) => {
    it(`returns ${outcome}`, () => {
      expect(
        getters[getterName]({
          reportInfo: {
            status: reportStatus,
          },
        }),
      ).toBe(outcome);
    });
  });
});
