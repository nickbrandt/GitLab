import state from 'ee/vue_shared/security_reports/store/state';
import {
  groupedSastText,
  groupedSastContainerText,
  groupedDastText,
  groupedDependencyText,
  groupedSummaryText,
  allReportsHaveError,
  noBaseInAllReports,
  areReportsLoading,
  sastStatusIcon,
  sastContainerStatusIcon,
  dastStatusIcon,
  dependencyScanningStatusIcon,
  anyReportHasError,
  summaryCounts,
} from 'ee/vue_shared/security_reports/store/getters';

const BASE_PATH = 'fake/base/path.json';
const HEAD_PATH = 'fake/head/path.json';

describe('Security reports getters', () => {
  function removeBreakLine(data) {
    return data.replace(/\r?\n|\r/g, '').replace(/\s\s+/g, ' ');
  }

  describe('groupedSastText', () => {
    describe('with no issues', () => {
      it('returns no issues text', () => {
        const newState = state();
        newState.sast.paths.head = HEAD_PATH;
        newState.sast.paths.base = BASE_PATH;

        expect(groupedSastText(newState)).toEqual('SAST detected no vulnerabilities');
      });
    });

    describe('with only `all` issues', () => {
      it('returns no new issues text', () => {
        const newState = state();
        newState.sast.paths.head = HEAD_PATH;
        newState.sast.paths.base = BASE_PATH;
        newState.sast.allIssues = [{}];

        expect(groupedSastText(newState)).toEqual('SAST detected no new vulnerabilities');
      });
    });

    describe('with new issues and without base', () => {
      it('returns unable to compare text', () => {
        const newState = state();
        newState.sast.paths.head = HEAD_PATH;
        newState.sast.newIssues = [{}];

        expect(groupedSastText(newState)).toEqual(
          'SAST detected 1 vulnerability for the source branch only',
        );
      });
    });

    describe('with base and head', () => {
      describe('with only new issues', () => {
        it('returns new issues text', () => {
          const newState = state();
          newState.sast.paths.head = HEAD_PATH;
          newState.sast.paths.base = BASE_PATH;
          newState.sast.newIssues = [{}];

          expect(groupedSastText(newState)).toEqual('SAST detected 1 new vulnerability');
        });
      });

      describe('with only dismissed issues', () => {
        it('returns dismissed issues text', () => {
          const newState = state();
          newState.sast.paths.head = HEAD_PATH;
          newState.sast.paths.base = BASE_PATH;
          newState.sast.newIssues = [{ isDismissed: true }];

          expect(groupedSastText(newState)).toEqual('SAST detected 1 dismissed vulnerability');
        });
      });

      describe('with new and resolved issues', () => {
        it('returns new and fixed issues text', () => {
          const newState = state();
          newState.sast.paths.head = HEAD_PATH;
          newState.sast.paths.base = BASE_PATH;
          newState.sast.newIssues = [{}];
          newState.sast.resolvedIssues = [{}];

          expect(removeBreakLine(groupedSastText(newState))).toEqual(
            'SAST detected 1 new, and 1 fixed vulnerabilities',
          );
        });
      });

      describe('with only resolved issues', () => {
        it('returns fixed issues text', () => {
          const newState = state();
          newState.sast.paths.head = HEAD_PATH;
          newState.sast.paths.base = BASE_PATH;
          newState.sast.resolvedIssues = [{}];

          expect(groupedSastText(newState)).toEqual('SAST detected 1 fixed vulnerability');
        });
      });

      describe('with error', () => {
        it('returns error text', () => {
          const newState = state();
          newState.sast.hasError = true;

          expect(groupedSastText(newState)).toEqual('SAST: Loading resulted in an error');
        });
      });

      describe('while loading', () => {
        it('returns loading text', () => {
          const newState = state();
          newState.sast.isLoading = true;

          expect(groupedSastText(newState)).toEqual('SAST is loading');
        });
      });
    });
  });

  describe('groupedSastContainerText', () => {
    describe('with no issues', () => {
      it('returns no issues text', () => {
        const newState = state();
        newState.sastContainer.paths.head = HEAD_PATH;
        newState.sastContainer.paths.base = BASE_PATH;

        expect(groupedSastContainerText(newState)).toEqual(
          'Container scanning detected no vulnerabilities',
        );
      });
    });

    describe('with new issues and without base', () => {
      it('returns unable to compare text', () => {
        const newState = state();
        newState.sastContainer.paths.head = HEAD_PATH;
        newState.sastContainer.newIssues = [{}];

        expect(groupedSastContainerText(newState)).toEqual(
          'Container scanning detected 1 vulnerability for the source branch only',
        );
      });
    });

    describe('with base and head', () => {
      describe('with only new issues', () => {
        it('returns new issues text', () => {
          const newState = state();
          newState.sastContainer.paths.head = HEAD_PATH;
          newState.sastContainer.paths.base = BASE_PATH;
          newState.sastContainer.newIssues = [{}];

          expect(groupedSastContainerText(newState)).toEqual(
            'Container scanning detected 1 new vulnerability',
          );
        });
      });

      describe('with only dismissed issues', () => {
        it('returns dismissed issues text', () => {
          const newState = state();
          newState.sastContainer.paths.head = HEAD_PATH;
          newState.sastContainer.paths.base = BASE_PATH;
          newState.sastContainer.newIssues = [{ isDismissed: true }];

          expect(groupedSastContainerText(newState)).toEqual(
            'Container scanning detected 1 dismissed vulnerability',
          );
        });
      });

      describe('with new and resolved issues', () => {
        it('returns new and fixed issues text', () => {
          const newState = state();
          newState.sastContainer.paths.head = HEAD_PATH;
          newState.sastContainer.paths.base = BASE_PATH;
          newState.sastContainer.newIssues = [{}];
          newState.sastContainer.resolvedIssues = [{}];

          expect(removeBreakLine(groupedSastContainerText(newState))).toEqual(
            'Container scanning detected 1 new, and 1 fixed vulnerabilities',
          );
        });
      });

      describe('with only resolved issues', () => {
        it('returns fixed issues text', () => {
          const newState = state();
          newState.sastContainer.paths.head = HEAD_PATH;
          newState.sastContainer.paths.base = BASE_PATH;
          newState.sastContainer.resolvedIssues = [{}];

          expect(groupedSastContainerText(newState)).toEqual(
            'Container scanning detected 1 fixed vulnerability',
          );
        });
      });
    });
  });

  describe('groupedDastText', () => {
    describe('with no issues', () => {
      it('returns no issues text', () => {
        const newState = state();
        newState.dast.paths.head = HEAD_PATH;
        newState.dast.paths.base = BASE_PATH;

        expect(groupedDastText(newState)).toEqual('DAST detected no vulnerabilities');
      });
    });

    describe('with new issues and without base', () => {
      it('returns unable to compare text', () => {
        const newState = state();
        newState.dast.paths.head = HEAD_PATH;
        newState.dast.newIssues = [{}];

        expect(groupedDastText(newState)).toEqual(
          'DAST detected 1 vulnerability for the source branch only',
        );
      });
    });

    describe('with base and head', () => {
      describe('with only new issues', () => {
        it('returns new issues text', () => {
          const newState = state();
          newState.dast.paths.head = HEAD_PATH;
          newState.dast.paths.base = BASE_PATH;
          newState.dast.newIssues = [{}];

          expect(groupedDastText(newState)).toEqual('DAST detected 1 new vulnerability');
        });
      });

      describe('with only dismissed issues', () => {
        it('returns dismissed issues text', () => {
          const newState = state();
          newState.dast.paths.head = HEAD_PATH;
          newState.dast.paths.base = BASE_PATH;
          newState.dast.newIssues = [{ isDismissed: true }];

          expect(groupedDastText(newState)).toEqual('DAST detected 1 dismissed vulnerability');
        });
      });

      describe('with new and resolved issues', () => {
        it('returns new and fixed issues text', () => {
          const newState = state();
          newState.dast.paths.head = HEAD_PATH;
          newState.dast.paths.base = BASE_PATH;
          newState.dast.newIssues = [{}];
          newState.dast.resolvedIssues = [{}];

          expect(removeBreakLine(groupedDastText(newState))).toEqual(
            'DAST detected 1 new, and 1 fixed vulnerabilities',
          );
        });
      });

      describe('with only resolved issues', () => {
        it('returns fixed issues text', () => {
          const newState = state();
          newState.dast.paths.head = HEAD_PATH;
          newState.dast.paths.base = BASE_PATH;
          newState.dast.resolvedIssues = [{}];

          expect(groupedDastText(newState)).toEqual('DAST detected 1 fixed vulnerability');
        });
      });
    });
  });

  describe('groupedDependencyText', () => {
    describe('with no issues', () => {
      it('returns no issues text', () => {
        const newState = state();
        newState.dependencyScanning.paths.head = HEAD_PATH;
        newState.dependencyScanning.paths.base = BASE_PATH;

        expect(groupedDependencyText(newState)).toEqual(
          'Dependency scanning detected no vulnerabilities',
        );
      });
    });

    describe('with new issues and without base', () => {
      it('returns unable to compare text', () => {
        const newState = state();
        newState.dependencyScanning.paths.head = HEAD_PATH;
        newState.dependencyScanning.newIssues = [{}];

        expect(groupedDependencyText(newState)).toEqual(
          'Dependency scanning detected 1 vulnerability for the source branch only',
        );
      });
    });

    describe('with base and head', () => {
      describe('with only new issues', () => {
        it('returns new issues text', () => {
          const newState = state();
          newState.dependencyScanning.paths.head = HEAD_PATH;
          newState.dependencyScanning.paths.base = BASE_PATH;
          newState.dependencyScanning.newIssues = [{}];

          expect(groupedDependencyText(newState)).toEqual(
            'Dependency scanning detected 1 new vulnerability',
          );
        });
      });

      describe('with only dismissed issues', () => {
        it('returns dismissed issues text', () => {
          const newState = state();
          newState.dependencyScanning.paths.head = HEAD_PATH;
          newState.dependencyScanning.paths.base = BASE_PATH;
          newState.dependencyScanning.newIssues = [{ isDismissed: true }];

          expect(groupedDependencyText(newState)).toEqual(
            'Dependency scanning detected 1 dismissed vulnerability',
          );
        });
      });

      describe('with new and resolved issues', () => {
        it('returns new and fixed issues text', () => {
          const newState = state();
          newState.dependencyScanning.paths.head = HEAD_PATH;
          newState.dependencyScanning.paths.base = BASE_PATH;
          newState.dependencyScanning.newIssues = [{}];
          newState.dependencyScanning.resolvedIssues = [{}];

          expect(removeBreakLine(groupedDependencyText(newState))).toEqual(
            'Dependency scanning detected 1 new, and 1 fixed vulnerabilities',
          );
        });
      });

      describe('with only resolved issues', () => {
        it('returns fixed issues text', () => {
          const newState = state();
          newState.dependencyScanning.paths.head = HEAD_PATH;
          newState.dependencyScanning.paths.base = BASE_PATH;

          newState.dependencyScanning.resolvedIssues = [{}];

          expect(groupedDependencyText(newState)).toEqual(
            'Dependency scanning detected 1 fixed vulnerability',
          );
        });
      });
    });
  });

  describe('summaryCounts', () => {
    it('returns 0 count for empty state', () => {
      const newState = state();

      expect(summaryCounts(newState)).toEqual({
        added: 0,
        dismissed: 0,
        existing: 0,
        fixed: 0,
      });
    });

    describe('combines all reports', () => {
      it('of the same type', () => {
        const newState = state();

        newState.sast.resolvedIssues = [{}];
        newState.sastContainer.resolvedIssues = [{}];
        newState.dast.resolvedIssues = [{}];
        newState.dependencyScanning.resolvedIssues = [{}];

        expect(summaryCounts(newState)).toEqual({
          added: 0,
          dismissed: 0,
          existing: 0,
          fixed: 4,
        });
      });

      it('of the different types', () => {
        const newState = state();

        newState.sast.allIssues = [{}];
        newState.sastContainer.resolvedIssues = [{}];
        newState.dast.newIssues = [{ isDismissed: true }];
        newState.dependencyScanning.newIssues = [{ isDismissed: false }];

        expect(summaryCounts(newState)).toEqual({
          added: 1,
          dismissed: 1,
          existing: 1,
          fixed: 1,
        });
      });
    });
  });

  describe('groupedSummaryText', () => {
    it('returns failed text', () => {
      expect(
        groupedSummaryText(state(), {
          allReportsHaveError: true,
          noBaseInAllReports: false,
          areReportsLoading: false,
          summaryCounts: {},
        }),
      ).toEqual('Security scanning failed loading any results');
    });

    it('returns no compare text', () => {
      expect(
        groupedSummaryText(state(), {
          allReportsHaveError: false,
          noBaseInAllReports: true,
          areReportsLoading: false,
          summaryCounts: {},
        }),
      ).toEqual('Security scanning detected no vulnerabilities for the source branch only');
    });

    it('returns is loading text', () => {
      expect(
        groupedSummaryText(state(), {
          allReportsHaveError: false,
          noBaseInAllReports: false,
          areReportsLoading: true,
          summaryCounts: {},
        }),
      ).toContain('(is loading)');
    });

    it('returns added and fixed text', () => {
      const newState = state();

      expect(
        groupedSummaryText(newState, {
          allReportsHaveError: false,
          noBaseInAllReports: false,
          areReportsLoading: false,
          summaryCounts: {
            added: 2,
            fixed: 4,
            existing: 5,
          },
        }),
      ).toEqual('Security scanning detected 2 new, and 4 fixed vulnerabilities');
    });

    it('returns added text', () => {
      const newState = state();

      expect(
        groupedSummaryText(newState, {
          allReportsHaveError: false,
          noBaseInAllReports: false,
          areReportsLoading: false,
          summaryCounts: {
            added: 2,
            existing: 5,
          },
        }),
      ).toEqual('Security scanning detected 2 new vulnerabilities');
    });

    it('returns fixed text', () => {
      const newState = state();

      expect(
        groupedSummaryText(newState, {
          allReportsHaveError: false,
          noBaseInAllReports: false,
          areReportsLoading: false,
          summaryCounts: {
            fixed: 4,
            existing: 5,
          },
        }),
      ).toEqual('Security scanning detected 4 fixed vulnerabilities');
    });

    it('returns dismissed text', () => {
      const newState = state();

      expect(
        groupedSummaryText(newState, {
          allReportsHaveError: false,
          noBaseInAllReports: false,
          areReportsLoading: false,
          summaryCounts: {
            dismissed: 4,
          },
        }),
      ).toEqual('Security scanning detected 4 dismissed vulnerabilities');
    });

    it('returns added and fixed while loading text', () => {
      const newState = state();

      expect(
        groupedSummaryText(newState, {
          allReportsHaveError: false,
          noBaseInAllReports: false,
          areReportsLoading: true,
          summaryCounts: {
            added: 2,
            fixed: 4,
            existing: 5,
          },
        }),
      ).toEqual('Security scanning (is loading) detected 2 new, and 4 fixed vulnerabilities');
    });

    it('returns no new text if there are existing ones', () => {
      const newState = state();

      expect(
        groupedSummaryText(newState, {
          allReportsHaveError: false,
          noBaseInAllReports: false,
          areReportsLoading: false,
          summaryCounts: {
            existing: 5,
          },
        }),
      ).toEqual('Security scanning detected no new vulnerabilities');
    });

    it('returns no text if there are existing ones', () => {
      const newState = state();

      expect(
        groupedSummaryText(newState, {
          allReportsHaveError: false,
          noBaseInAllReports: false,
          areReportsLoading: false,
          summaryCounts: {},
        }),
      ).toEqual('Security scanning detected no vulnerabilities');
    });
  });

  describe('sastStatusIcon', () => {
    it('returns warning with new issues', () => {
      const newState = state();
      newState.sast.newIssues = [{}];

      expect(sastStatusIcon(newState)).toEqual('warning');
    });

    it('returns warning with failed report', () => {
      const newState = state();
      newState.sast.hasError = true;

      expect(sastStatusIcon(newState)).toEqual('warning');
    });

    it('returns success with no new issues or failed report', () => {
      expect(sastStatusIcon(state())).toEqual('success');
    });
  });

  describe('dastStatusIcon', () => {
    it('returns warning with new issues', () => {
      const newState = state();
      newState.dast.newIssues = [{}];

      expect(dastStatusIcon(newState)).toEqual('warning');
    });

    it('returns warning with failed report', () => {
      const newState = state();
      newState.dast.hasError = true;

      expect(dastStatusIcon(newState)).toEqual('warning');
    });

    it('returns success with no new issues or failed report', () => {
      expect(dastStatusIcon(state())).toEqual('success');
    });
  });

  describe('sastContainerStatusIcon', () => {
    it('returns warning with new issues', () => {
      const newState = state();
      newState.sastContainer.newIssues = [{}];

      expect(sastContainerStatusIcon(newState)).toEqual('warning');
    });

    it('returns warning with failed report', () => {
      const newState = state();
      newState.sastContainer.hasError = true;

      expect(sastContainerStatusIcon(newState)).toEqual('warning');
    });

    it('returns success with no new issues or failed report', () => {
      expect(sastContainerStatusIcon(state())).toEqual('success');
    });
  });

  describe('dependencyScanningStatusIcon', () => {
    it('returns warning with new issues', () => {
      const newState = state();
      newState.dependencyScanning.newIssues = [{}];

      expect(dependencyScanningStatusIcon(newState)).toEqual('warning');
    });

    it('returns warning with failed report', () => {
      const newState = state();
      newState.dependencyScanning.hasError = true;

      expect(dependencyScanningStatusIcon(newState)).toEqual('warning');
    });

    it('returns success with no new issues or failed report', () => {
      expect(dependencyScanningStatusIcon(state())).toEqual('success');
    });
  });

  describe('areReportsLoading', () => {
    it('returns true when any report is loading', () => {
      const newState = state();
      newState.sast.isLoading = true;

      expect(areReportsLoading(newState)).toEqual(true);
    });

    it('returns false when none of the reports are loading', () => {
      expect(areReportsLoading(state())).toEqual(false);
    });
  });

  describe('allReportsHaveError', () => {
    it('returns true when all reports have error', () => {
      const newState = state();
      newState.sast.hasError = true;
      newState.dast.hasError = true;
      newState.sastContainer.hasError = true;
      newState.dependencyScanning.hasError = true;

      expect(allReportsHaveError(newState)).toEqual(true);
    });

    it('returns false when none of the reports have error', () => {
      expect(allReportsHaveError(state())).toEqual(false);
    });

    it('returns false when one of the reports does not have error', () => {
      const newState = state();
      newState.sast.hasError = false;
      newState.dast.hasError = true;
      newState.sastContainer.hasError = true;
      newState.dependencyScanning.hasError = true;

      expect(allReportsHaveError(newState)).toEqual(false);
    });
  });

  describe('anyReportHasError', () => {
    it('returns true when any of the reports has error', () => {
      const newState = state();
      newState.sast.hasError = true;

      expect(anyReportHasError(newState)).toEqual(true);
    });

    it('returns false when none of the reports has error', () => {
      expect(anyReportHasError(state())).toEqual(false);
    });
  });

  describe('noBaseInAllReports', () => {
    it('returns true when none reports have base', () => {
      expect(noBaseInAllReports(state())).toEqual(true);
    });

    it('returns false when any of the reports has base', () => {
      const newState = state();
      newState.sast.paths.base = BASE_PATH;

      expect(noBaseInAllReports(newState)).toEqual(false);
    });
  });
});
