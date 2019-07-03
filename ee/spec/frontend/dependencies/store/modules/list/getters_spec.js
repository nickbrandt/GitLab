import { TEST_HOST } from 'helpers/test_constants';
import * as getters from 'ee/dependencies/store/modules/list/getters';
import { REPORT_STATUS } from 'ee/dependencies/store/modules/list/constants';

describe('Dependencies getters', () => {
  describe.each`
    getterName         | reportStatus                    | outcome
    ${'isJobNotSetUp'} | ${REPORT_STATUS.jobNotSetUp}    | ${true}
    ${'isJobNotSetUp'} | ${REPORT_STATUS.ok}             | ${false}
    ${'isJobFailed'}   | ${REPORT_STATUS.jobFailed}      | ${true}
    ${'isJobFailed'}   | ${REPORT_STATUS.noDependencies} | ${true}
    ${'isJobFailed'}   | ${REPORT_STATUS.ok}             | ${false}
    ${'isIncomplete'}  | ${REPORT_STATUS.incomplete}     | ${true}
    ${'isIncomplete'}  | ${REPORT_STATUS.ok}             | ${false}
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

  describe('downloadEndpoint', () => {
    it('should return download endpoint', () => {
      const endpoint = `${TEST_HOST}/dependencies`;
      expect(getters.downloadEndpoint({ endpoint })).toBe(`${TEST_HOST}/dependencies.json`);
    });
  });
});
