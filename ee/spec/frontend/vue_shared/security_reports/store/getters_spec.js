import createState from 'ee/vue_shared/security_reports/store/state';
import createSastState from 'ee/vue_shared/security_reports/store/modules/sast/state';
import {
  groupedContainerScanningText,
  groupedDastText,
  groupedDependencyText,
  groupedSecretScanningText,
  groupedSummaryText,
  allReportsHaveError,
  noBaseInAllReports,
  areReportsLoading,
  containerScanningStatusIcon,
  dastStatusIcon,
  dependencyScanningStatusIcon,
  anyReportHasError,
  summaryCounts,
  isBaseSecurityReportOutOfDate,
  canCreateIssue,
  canCreateMergeRequest,
  canDismissVulnerability,
} from 'ee/vue_shared/security_reports/store/getters';

const BASE_PATH = 'fake/base/path.json';
const HEAD_PATH = 'fake/head/path.json';
const MOCK_PATH = 'fake/path.json';

describe('Security reports getters', () => {
  function removeBreakLine(data) {
    return data.replace(/\r?\n|\r/g, '').replace(/\s\s+/g, ' ');
  }

  let state;

  beforeEach(() => {
    state = createState();
    state.sast = createSastState();
  });

  describe('groupedContainerScanningText', () => {
    describe('with no issues', () => {
      it('returns no issues text', () => {
        state.containerScanning.paths.head = HEAD_PATH;
        state.containerScanning.paths.base = BASE_PATH;

        expect(groupedContainerScanningText(state)).toEqual(
          'Container scanning detected no vulnerabilities',
        );
      });
    });

    describe('with new issues and without base', () => {
      it('returns unable to compare text', () => {
        state.containerScanning.paths.head = HEAD_PATH;
        state.containerScanning.newIssues = [{}];

        expect(groupedContainerScanningText(state)).toEqual(
          'Container scanning detected 1 vulnerability for the source branch only',
        );
      });
    });

    describe('with base and head', () => {
      describe('with only new issues', () => {
        it('returns new issues text', () => {
          state.containerScanning.paths.head = HEAD_PATH;
          state.containerScanning.paths.base = BASE_PATH;
          state.containerScanning.newIssues = [{}];

          expect(groupedContainerScanningText(state)).toEqual(
            'Container scanning detected 1 new vulnerability',
          );
        });
      });

      describe('with only dismissed issues', () => {
        it('returns dismissed issues text', () => {
          state.containerScanning.paths.head = HEAD_PATH;
          state.containerScanning.paths.base = BASE_PATH;
          state.containerScanning.newIssues = [{ isDismissed: true }];

          expect(groupedContainerScanningText(state)).toEqual(
            'Container scanning detected 1 dismissed vulnerability',
          );
        });
      });

      describe('with new and resolved issues', () => {
        it('returns new and fixed issues text', () => {
          state.containerScanning.paths.head = HEAD_PATH;
          state.containerScanning.paths.base = BASE_PATH;
          state.containerScanning.newIssues = [{}];
          state.containerScanning.resolvedIssues = [{}];

          expect(removeBreakLine(groupedContainerScanningText(state))).toEqual(
            'Container scanning detected 1 new, and 1 fixed vulnerabilities',
          );
        });
      });

      describe('with only resolved issues', () => {
        it('returns fixed issues text', () => {
          state.containerScanning.paths.head = HEAD_PATH;
          state.containerScanning.paths.base = BASE_PATH;
          state.containerScanning.resolvedIssues = [{}];

          expect(groupedContainerScanningText(state)).toEqual(
            'Container scanning detected 1 fixed vulnerability',
          );
        });
      });
    });
  });

  describe('groupedDastText', () => {
    describe('with no issues', () => {
      it('returns no issues text', () => {
        state.dast.paths.head = HEAD_PATH;
        state.dast.paths.base = BASE_PATH;

        expect(groupedDastText(state)).toEqual('DAST detected no vulnerabilities');
      });
    });

    describe('with new issues and without base', () => {
      it('returns unable to compare text', () => {
        state.dast.paths.head = HEAD_PATH;
        state.dast.newIssues = [{}];

        expect(groupedDastText(state)).toEqual(
          'DAST detected 1 vulnerability for the source branch only',
        );
      });
    });

    describe('with base and head', () => {
      describe('with only new issues', () => {
        it('returns new issues text', () => {
          state.dast.paths.head = HEAD_PATH;
          state.dast.paths.base = BASE_PATH;
          state.dast.newIssues = [{}];

          expect(groupedDastText(state)).toEqual('DAST detected 1 new vulnerability');
        });
      });

      describe('with only dismissed issues', () => {
        it('returns dismissed issues text', () => {
          state.dast.paths.head = HEAD_PATH;
          state.dast.paths.base = BASE_PATH;
          state.dast.newIssues = [{ isDismissed: true }];

          expect(groupedDastText(state)).toEqual('DAST detected 1 dismissed vulnerability');
        });
      });

      describe('with new and resolved issues', () => {
        it('returns new and fixed issues text', () => {
          state.dast.paths.head = HEAD_PATH;
          state.dast.paths.base = BASE_PATH;
          state.dast.newIssues = [{}];
          state.dast.resolvedIssues = [{}];

          expect(removeBreakLine(groupedDastText(state))).toEqual(
            'DAST detected 1 new, and 1 fixed vulnerabilities',
          );
        });
      });

      describe('with only resolved issues', () => {
        it('returns fixed issues text', () => {
          state.dast.paths.head = HEAD_PATH;
          state.dast.paths.base = BASE_PATH;
          state.dast.resolvedIssues = [{}];

          expect(groupedDastText(state)).toEqual('DAST detected 1 fixed vulnerability');
        });
      });
    });
  });

  describe('groupedDependencyText', () => {
    describe('with no issues', () => {
      it('returns no issues text', () => {
        state.dependencyScanning.paths.head = HEAD_PATH;
        state.dependencyScanning.paths.base = BASE_PATH;

        expect(groupedDependencyText(state)).toEqual(
          'Dependency scanning detected no vulnerabilities',
        );
      });
    });

    describe('with new issues and without base', () => {
      it('returns unable to compare text', () => {
        state.dependencyScanning.paths.head = HEAD_PATH;
        state.dependencyScanning.newIssues = [{}];

        expect(groupedDependencyText(state)).toEqual(
          'Dependency scanning detected 1 vulnerability for the source branch only',
        );
      });
    });

    describe('with base and head', () => {
      describe('with only new issues', () => {
        it('returns new issues text', () => {
          state.dependencyScanning.paths.head = HEAD_PATH;
          state.dependencyScanning.paths.base = BASE_PATH;
          state.dependencyScanning.newIssues = [{}];

          expect(groupedDependencyText(state)).toEqual(
            'Dependency scanning detected 1 new vulnerability',
          );
        });
      });

      describe('with only dismissed issues', () => {
        it('returns dismissed issues text', () => {
          state.dependencyScanning.paths.head = HEAD_PATH;
          state.dependencyScanning.paths.base = BASE_PATH;
          state.dependencyScanning.newIssues = [{ isDismissed: true }];

          expect(groupedDependencyText(state)).toEqual(
            'Dependency scanning detected 1 dismissed vulnerability',
          );
        });
      });

      describe('with new and resolved issues', () => {
        it('returns new and fixed issues text', () => {
          state.dependencyScanning.paths.head = HEAD_PATH;
          state.dependencyScanning.paths.base = BASE_PATH;
          state.dependencyScanning.newIssues = [{}];
          state.dependencyScanning.resolvedIssues = [{}];

          expect(removeBreakLine(groupedDependencyText(state))).toEqual(
            'Dependency scanning detected 1 new, and 1 fixed vulnerabilities',
          );
        });
      });

      describe('with only resolved issues', () => {
        it('returns fixed issues text', () => {
          state.dependencyScanning.paths.head = HEAD_PATH;
          state.dependencyScanning.paths.base = BASE_PATH;

          state.dependencyScanning.resolvedIssues = [{}];

          expect(groupedDependencyText(state)).toEqual(
            'Dependency scanning detected 1 fixed vulnerability',
          );
        });
      });
    });
  });

  describe('groupedSecretScanningText', () => {
    describe('with no issues', () => {
      it('returns no issues text', () => {
        state.secretScanning.paths.head = HEAD_PATH;
        state.secretScanning.paths.base = BASE_PATH;

        expect(groupedSecretScanningText(state)).toEqual(
          'Secret scanning detected no vulnerabilities',
        );
      });
    });

    describe('with new issues and without base', () => {
      it('returns unable to compare text', () => {
        state.secretScanning.paths.head = HEAD_PATH;
        state.secretScanning.newIssues = [{}];

        expect(groupedSecretScanningText(state)).toEqual(
          'Secret scanning detected 1 vulnerability for the source branch only',
        );
      });
    });

    describe('with base and head', () => {
      describe('with only new issues', () => {
        it('returns new issues text', () => {
          state.secretScanning.paths.head = HEAD_PATH;
          state.secretScanning.paths.base = BASE_PATH;
          state.secretScanning.newIssues = [{}];

          expect(groupedSecretScanningText(state)).toEqual(
            'Secret scanning detected 1 new vulnerability',
          );
        });
      });

      describe('with only dismissed issues', () => {
        it('returns dismissed issues text', () => {
          state.secretScanning.paths.head = HEAD_PATH;
          state.secretScanning.paths.base = BASE_PATH;
          state.secretScanning.newIssues = [{ isDismissed: true }];

          expect(groupedSecretScanningText(state)).toEqual(
            'Secret scanning detected 1 dismissed vulnerability',
          );
        });
      });

      describe('with new and resolved issues', () => {
        it('returns new and fixed issues text', () => {
          state.secretScanning.paths.head = HEAD_PATH;
          state.secretScanning.paths.base = BASE_PATH;
          state.secretScanning.newIssues = [{}];
          state.secretScanning.resolvedIssues = [{}];

          expect(removeBreakLine(groupedSecretScanningText(state))).toEqual(
            'Secret scanning detected 1 new, and 1 fixed vulnerabilities',
          );
        });
      });

      describe('with only resolved issues', () => {
        it('returns fixed issues text', () => {
          state.secretScanning.paths.head = HEAD_PATH;
          state.secretScanning.paths.base = BASE_PATH;
          state.secretScanning.resolvedIssues = [{}];

          expect(groupedSecretScanningText(state)).toEqual(
            'Secret scanning detected 1 fixed vulnerability',
          );
        });
      });
    });
  });

  describe('summaryCounts', () => {
    it('returns 0 count for empty state', () => {
      expect(summaryCounts(state)).toEqual({
        added: 0,
        dismissed: 0,
        existing: 0,
        fixed: 0,
      });
    });

    describe('combines all reports', () => {
      it('of the same type', () => {
        state.containerScanning.resolvedIssues = [{}];
        state.dast.resolvedIssues = [{}];
        state.dependencyScanning.resolvedIssues = [{}];

        expect(summaryCounts(state)).toEqual({
          added: 0,
          dismissed: 0,
          existing: 0,
          fixed: 3,
        });
      });

      it('of the different types', () => {
        state.containerScanning.resolvedIssues = [{}];
        state.dast.allIssues = [{}];
        state.dast.newIssues = [{ isDismissed: true }];
        state.dependencyScanning.newIssues = [{ isDismissed: false }];

        expect(summaryCounts(state)).toEqual({
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
        groupedSummaryText(state, {
          allReportsHaveError: true,
          noBaseInAllReports: false,
          areReportsLoading: false,
          summaryCounts: {},
        }),
      ).toEqual('Security scanning failed loading any results');
    });

    it('returns no compare text', () => {
      expect(
        groupedSummaryText(state, {
          allReportsHaveError: false,
          noBaseInAllReports: true,
          areReportsLoading: false,
          summaryCounts: {},
        }),
      ).toEqual('Security scanning detected no vulnerabilities for the source branch only');
    });

    it('returns is loading text', () => {
      expect(
        groupedSummaryText(state, {
          allReportsHaveError: false,
          noBaseInAllReports: false,
          areReportsLoading: true,
          summaryCounts: {},
        }),
      ).toContain('(is loading)');
    });

    it('returns added and fixed text', () => {
      expect(
        groupedSummaryText(state, {
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
      expect(
        groupedSummaryText(state, {
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
      expect(
        groupedSummaryText(state, {
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
      expect(
        groupedSummaryText(state, {
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
      expect(
        groupedSummaryText(state, {
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
      expect(
        groupedSummaryText(state, {
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
      expect(
        groupedSummaryText(state, {
          allReportsHaveError: false,
          noBaseInAllReports: false,
          areReportsLoading: false,
          summaryCounts: {},
        }),
      ).toEqual('Security scanning detected no vulnerabilities');
    });
  });

  describe('dastStatusIcon', () => {
    it('returns warning with new issues', () => {
      state.dast.newIssues = [{}];

      expect(dastStatusIcon(state)).toEqual('warning');
    });

    it('returns warning with failed report', () => {
      state.dast.hasError = true;

      expect(dastStatusIcon(state)).toEqual('warning');
    });

    it('returns success with no new issues or failed report', () => {
      expect(dastStatusIcon(state)).toEqual('success');
    });
  });

  describe('containerScanningStatusIcon', () => {
    it('returns warning with new issues', () => {
      state.containerScanning.newIssues = [{}];

      expect(containerScanningStatusIcon(state)).toEqual('warning');
    });

    it('returns warning with failed report', () => {
      state.containerScanning.hasError = true;

      expect(containerScanningStatusIcon(state)).toEqual('warning');
    });

    it('returns success with no new issues or failed report', () => {
      expect(containerScanningStatusIcon(state)).toEqual('success');
    });
  });

  describe('dependencyScanningStatusIcon', () => {
    it('returns warning with new issues', () => {
      state.dependencyScanning.newIssues = [{}];

      expect(dependencyScanningStatusIcon(state)).toEqual('warning');
    });

    it('returns warning with failed report', () => {
      state.dependencyScanning.hasError = true;

      expect(dependencyScanningStatusIcon(state)).toEqual('warning');
    });

    it('returns success with no new issues or failed report', () => {
      expect(dependencyScanningStatusIcon(state)).toEqual('success');
    });
  });

  describe('areReportsLoading', () => {
    it('returns true when any report is loading', () => {
      state.dast.isLoading = true;

      expect(areReportsLoading(state)).toEqual(true);
    });

    it('returns false when none of the reports are loading', () => {
      expect(areReportsLoading(state)).toEqual(false);
    });
  });

  describe('allReportsHaveError', () => {
    it('returns true when all reports have error', () => {
      state.sast.hasError = true;
      state.dast.hasError = true;
      state.containerScanning.hasError = true;
      state.dependencyScanning.hasError = true;
      state.secretScanning.hasError = true;

      expect(allReportsHaveError(state)).toEqual(true);
    });

    it('returns false when none of the reports have error', () => {
      expect(allReportsHaveError(state)).toEqual(false);
    });

    it('returns false when one of the reports does not have error', () => {
      state.dast.hasError = false;
      state.containerScanning.hasError = true;
      state.dependencyScanning.hasError = true;
      state.secretScanning.hasError = true;

      expect(allReportsHaveError(state)).toEqual(false);
    });
  });

  describe('anyReportHasError', () => {
    it('returns true when any of the reports has error', () => {
      state.dast.hasError = true;

      expect(anyReportHasError(state)).toEqual(true);
    });

    it('returns false when none of the reports has error', () => {
      expect(anyReportHasError(state)).toEqual(false);
    });
  });

  describe('noBaseInAllReports', () => {
    it('returns true when none reports have base', () => {
      expect(noBaseInAllReports(state)).toEqual(true);
    });

    it('returns false when any of the reports has a base', () => {
      state.dast.hasBaseReport = true;

      expect(noBaseInAllReports(state)).toEqual(false);
    });
  });

  describe('isBaseSecurityReportOutOfDate', () => {
    it('returns false when none reports are out of date', () => {
      expect(isBaseSecurityReportOutOfDate(state)).toEqual(false);
    });

    it('returns true when any of the reports is out of date', () => {
      state.dast.baseReportOutofDate = true;
      expect(isBaseSecurityReportOutOfDate(state)).toEqual(true);
    });
  });

  describe('canCreateIssue', () => {
    it('returns false if no feedback path is defined', () => {
      expect(canCreateIssue(state)).toEqual(false);
    });

    it('returns true if a feedback path is defined', () => {
      state.createVulnerabilityFeedbackIssuePath = MOCK_PATH;

      expect(canCreateIssue(state)).toEqual(true);
    });
  });

  describe('canCreateMergeRequest', () => {
    it('returns false if no feedback path is defined', () => {
      expect(canCreateMergeRequest(state)).toEqual(false);
    });

    it('returns true if a feedback path is defined', () => {
      state.createVulnerabilityFeedbackMergeRequestPath = MOCK_PATH;

      expect(canCreateMergeRequest(state)).toEqual(true);
    });
  });

  describe('canDismissVulnerability', () => {
    it('returns false if no feedback path is defined', () => {
      expect(canDismissVulnerability(state)).toEqual(false);
    });

    it('returns true if a feedback path is defined', () => {
      state.createVulnerabilityFeedbackDismissalPath = MOCK_PATH;

      expect(canDismissVulnerability(state)).toEqual(true);
    });
  });
});
