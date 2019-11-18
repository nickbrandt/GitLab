import sha1 from 'sha1';
import {
  findIssueIndex,
  findMatchingRemediations,
  parseSastIssues,
  parseDependencyScanningIssues,
  getDastSites,
  parseDastIssues,
  getUnapprovedVulnerabilities,
  groupedTextBuilder,
  statusIcon,
  countIssues,
  groupedReportText,
} from 'ee/vue_shared/security_reports/store/utils';
import filterByKey from 'ee/vue_shared/security_reports/store/utils/filter_by_key';
import getFileLocation from 'ee/vue_shared/security_reports/store/utils/get_file_location';
import {
  formatContainerScanningDescription,
  formatContainerScanningMessage,
  formatContainerScanningSolution,
  parseContainerScanningSeverity,
  parseSastContainer,
} from 'ee/vue_shared/security_reports/store/utils/container_scanning';
import { SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';
import {
  oldSastIssues,
  sastIssues,
  sastIssuesMajor2,
  sastFeedbacks,
  dependencyScanningIssuesOld,
  dependencyScanningIssues,
  dependencyScanningIssuesMajor2,
  dependencyScanningFeedbacks,
  dockerReport,
  containerScanningFeedbacks,
  dast,
  multiSitesDast,
  dastFeedbacks,
  parsedMultiSitesDast,
  parsedDast,
} from '../mock_data';

describe('security reports utils', () => {
  describe('findIssueIndex', () => {
    let issuesList;

    beforeEach(() => {
      issuesList = [
        { project_fingerprint: 'abc123' },
        { project_fingerprint: 'abc456' },
        { project_fingerprint: 'abc789' },
      ];
    });

    it('returns index of found issue', () => {
      const issue = {
        project_fingerprint: 'abc456',
      };

      expect(findIssueIndex(issuesList, issue)).toEqual(1);
    });

    it('returns -1 when issue is not found', () => {
      const issue = {
        project_fingerprint: 'foo',
      };

      expect(findIssueIndex(issuesList, issue)).toEqual(-1);
    });
  });

  describe('findMatchingRemediations', () => {
    const remediation1 = {
      fixes: [
        {
          cve: '123',
        },
        {
          foobar: 'baz',
        },
      ],
      summary: 'Update to x.y.z',
    };

    const remediation2 = { ...remediation1, summary: 'Remediation2' };

    const impossibleRemediation = {
      fixes: [],
      summary: 'Impossible',
    };

    const remediations = [impossibleRemediation, remediation1, remediation2];

    it('returns null for empty vulnerability', () => {
      expect(findMatchingRemediations(remediations, {})).toHaveLength(0);
      expect(findMatchingRemediations(remediations, null)).toHaveLength(0);
      expect(findMatchingRemediations(remediations, undefined)).toHaveLength(0);
    });

    it('returns empty arrays for empty remediations', () => {
      expect(findMatchingRemediations([], { cve: '123' })).toHaveLength(0);
      expect(findMatchingRemediations(null, { cve: '123' })).toHaveLength(0);
      expect(findMatchingRemediations(undefined, { cve: '123' })).toHaveLength(0);
    });

    it('returns an empty array for vulnerabilities without a remediation', () => {
      expect(findMatchingRemediations(remediations, { cve: 'NOT_FOUND' })).toHaveLength(0);
    });

    it('returns all matching remediations for a vulnerability', () => {
      expect(findMatchingRemediations(remediations, { cve: '123' })).toEqual([
        remediation1,
        remediation2,
      ]);

      expect(findMatchingRemediations(remediations, { foobar: 'baz' })).toEqual([
        remediation1,
        remediation2,
      ]);
    });
  });

  describe('parseSastIssues', () => {
    it('should parse the received issues with old JSON format', () => {
      const parsed = parseSastIssues(oldSastIssues, [], 'path')[0];

      expect(parsed.title).toEqual(sastIssues[0].message);
      expect(parsed.path).toEqual(sastIssues[0].location.file);
      expect(parsed.location.start_line).toEqual(sastIssues[0].location.start_line);
      expect(parsed.location.end_line).toBeUndefined();
      expect(parsed.urlPath).toEqual('path/Gemfile.lock#L5');
      expect(parsed.project_fingerprint).toEqual(sha1(sastIssues[0].cve));
    });

    it('should parse the received issues with new JSON format', () => {
      const parsed = parseSastIssues(sastIssues, [], 'path')[0];

      expect(parsed.title).toEqual(sastIssues[0].message);
      expect(parsed.path).toEqual(sastIssues[0].location.file);
      expect(parsed.location.start_line).toEqual(sastIssues[0].location.start_line);
      expect(parsed.location.end_line).toEqual(sastIssues[0].location.end_line);
      expect(parsed.urlPath).toEqual('path/Gemfile.lock#L5-10');
      expect(parsed.project_fingerprint).toEqual(sha1(sastIssues[0].cve));
    });

    it('should parse the received issues with new JSON format (2.0)', () => {
      const raw = sastIssues[0];
      const parsed = parseSastIssues(sastIssuesMajor2, [], 'path')[0];

      expect(parsed.title).toEqual(raw.message);
      expect(parsed.path).toEqual(raw.location.file);
      expect(parsed.location.start_line).toEqual(raw.location.start_line);
      expect(parsed.location.end_line).toEqual(raw.location.end_line);
      expect(parsed.urlPath).toEqual('path/Gemfile.lock#L5-10');
      expect(parsed.project_fingerprint).toEqual(sha1(raw.cve));
    });

    it('generate correct path to file when there is no line', () => {
      const parsed = parseSastIssues(sastIssues, [], 'path')[1];

      expect(parsed.urlPath).toEqual('path/Gemfile.lock');
    });

    it('includes vulnerability feedbacks', () => {
      const parsed = parseSastIssues(sastIssues, sastFeedbacks, 'path')[0];

      expect(parsed.hasIssue).toEqual(true);
      expect(parsed.isDismissed).toEqual(true);
      expect(parsed.dismissalFeedback).toEqual(sastFeedbacks[0]);
      expect(parsed.issue_feedback).toEqual(sastFeedbacks[1]);
    });
  });

  describe('parseDependencyScanningIssues', () => {
    it('should parse the received issues', () => {
      const parsed = parseDependencyScanningIssues(dependencyScanningIssuesOld, [], 'path')[0];

      expect(parsed.title).toEqual(dependencyScanningIssuesOld[0].message);
      expect(parsed.path).toEqual(dependencyScanningIssuesOld[0].file);
      expect(parsed.location.start_line).toEqual(parseInt(dependencyScanningIssuesOld[0].line, 10));
      expect(parsed.location.end_line).toBeUndefined();
      expect(parsed.urlPath).toEqual('path/Gemfile.lock#L5');
      expect(parsed.project_fingerprint).toEqual(sha1(dependencyScanningIssuesOld[0].cve));
    });

    it('should parse the received issues with new JSON format', () => {
      const raw = dependencyScanningIssues[0];
      const parsed = parseDependencyScanningIssues(dependencyScanningIssues, [], 'path')[0];

      expect(parsed.title).toEqual(raw.message);
      expect(parsed.path).toEqual(raw.location.file);
      expect(parsed.location.start_line).toBeUndefined();
      expect(parsed.location.end_line).toBeUndefined();
      expect(parsed.urlPath).toEqual(`path/${raw.location.file}`);
      expect(parsed.project_fingerprint).toEqual(sha1(raw.cve));
    });

    it('should parse the received issues with new JSON format (2.0)', () => {
      const raw = dependencyScanningIssues[0];
      const parsed = parseDependencyScanningIssues(dependencyScanningIssuesMajor2, [], 'path')[0];

      expect(parsed.title).toEqual(raw.message);
      expect(parsed.path).toEqual(raw.location.file);
      expect(parsed.location.start_line).toBeUndefined();
      expect(parsed.location.end_line).toBeUndefined();
      expect(parsed.urlPath).toEqual(`path/${raw.location.file}`);
      expect(parsed.project_fingerprint).toEqual(sha1(raw.cve));
      expect(parsed.remediations).toEqual([dependencyScanningIssuesMajor2.remediations[0]]);
    });

    it('generate correct path to file when there is no line', () => {
      const parsed = parseDependencyScanningIssues(dependencyScanningIssuesOld, [], 'path')[1];

      expect(parsed.urlPath).toEqual('path/Gemfile.lock');
    });

    it('includes vulnerability feedbacks', () => {
      const parsed = parseDependencyScanningIssues(
        dependencyScanningIssuesOld,
        dependencyScanningFeedbacks,
        'path',
      )[0];

      expect(parsed.hasIssue).toEqual(true);
      expect(parsed.isDismissed).toEqual(true);
      expect(parsed.dismissalFeedback).toEqual(dependencyScanningFeedbacks[0]);
      expect(parsed.issue_feedback).toEqual(dependencyScanningFeedbacks[1]);
    });
  });

  describe('container scanning utils', () => {
    describe('formatContainerScanningSolution', () => {
      it('should return false if there is no data', () => {
        expect(formatContainerScanningSolution({})).toBe(null);
      });

      it('should return the correct sentence', () => {
        expect(formatContainerScanningSolution({ fixedby: 'v9000' })).toBe('Upgrade to v9000.');
        expect(
          formatContainerScanningSolution({ fixedby: 'v9000', featurename: 'Dependency' }),
        ).toBe('Upgrade Dependency to v9000.');

        expect(
          formatContainerScanningSolution({
            fixedby: 'v9000',
            featurename: 'Dependency',
            featureversion: '1.0-beta',
          }),
        ).toBe('Upgrade Dependency from 1.0-beta to v9000.');
      });
    });

    describe('formatContainerScanningMessage', () => {
      it('should return concatenated message if vulnerability and featurename are provided', () => {
        expect(
          formatContainerScanningMessage({ vulnerability: 'CVE-124', featurename: 'grep' }),
        ).toBe('CVE-124 in grep');
      });

      it('should return vulnerability if only that is provided', () => {
        expect(formatContainerScanningMessage({ vulnerability: 'Foo' })).toBe('Foo');
      });
    });

    describe('formatContainerScanningDescription', () => {
      it('should return description', () => {
        expect(formatContainerScanningDescription({ description: 'Foobar' })).toBe('Foobar');
      });

      it('should build description from available fields', () => {
        const featurename = 'Dependency';
        const featureversion = '1.0';
        const namespace = 'debian:8';
        const vulnerability = 'CVE-123';

        expect(
          formatContainerScanningDescription({
            featurename,
            featureversion,
            namespace,
            vulnerability,
          }),
        ).toBe('Dependency:1.0 is affected by CVE-123.');

        expect(formatContainerScanningDescription({ featurename, namespace, vulnerability })).toBe(
          'Dependency is affected by CVE-123.',
        );

        expect(formatContainerScanningDescription({ namespace, vulnerability })).toBe(
          'debian:8 is affected by CVE-123.',
        );
      });
    });

    describe('parseContainerScanningSeverity', () => {
      it('should return `Critical` for `Defcon1`', () => {
        expect(parseContainerScanningSeverity('Defcon1')).toBe(SEVERITY_LEVELS.critical);
      });

      it('should return `Low` for `Negligible`', () => {
        expect(parseContainerScanningSeverity('Negligible')).toBe('Low');
      });

      it('should not touch other severities', () => {
        expect(parseContainerScanningSeverity('oxofrmbl')).toBe('oxofrmbl');
        expect(parseContainerScanningSeverity('Medium')).toBe('Medium');
        expect(parseContainerScanningSeverity('High')).toBe('High');
      });
    });
  });

  describe('parseSastContainer', () => {
    it('parses sast container issues', () => {
      const parsed = parseSastContainer(dockerReport.vulnerabilities)[0];
      const issue = dockerReport.vulnerabilities[0];

      expect(parsed.title).toEqual(issue.vulnerability);
      expect(parsed.identifiers).toEqual([
        {
          type: 'CVE',
          name: issue.vulnerability,
          value: issue.vulnerability,
          url: `https://cve.mitre.org/cgi-bin/cvename.cgi?name=${issue.vulnerability}`,
        },
      ]);

      expect(parsed.project_fingerprint).toEqual(sha1(issue.vulnerability));
    });

    it('includes vulnerability feedbacks', () => {
      const parsed = parseSastContainer(
        dockerReport.vulnerabilities,
        containerScanningFeedbacks,
      )[0];

      expect(parsed.hasIssue).toEqual(true);
      expect(parsed.isDismissed).toEqual(true);
      expect(parsed.dismissalFeedback).toEqual(containerScanningFeedbacks[0]);
      expect(parsed.issue_feedback).toEqual(containerScanningFeedbacks[1]);
    });
  });

  describe('getDastSites', () => {
    it.each([{}, 'site', 1, undefined])('wraps non-array argument %p into an array', arg => {
      expect(getDastSites(arg)).toEqual([arg]);
    });

    it("returns argument if it's an array", () => {
      const sites = [];
      expect(getDastSites(sites)).toEqual(sites);
    });
  });

  describe('parseDastIssues', () => {
    it.each`
      description                  | report
      ${'multi-sites dast report'} | ${multiSitesDast}
      ${'legacy dast report'}      | ${dast}
    `('includes vulnerability feedbacks in $description', ({ report }) => {
      const parsed = parseDastIssues(report.site, dastFeedbacks)[0];

      expect(parsed.hasIssue).toEqual(true);
      expect(parsed.isDismissed).toEqual(true);
      expect(parsed.dismissalFeedback).toEqual(dastFeedbacks[0]);
      expect(parsed.issue_feedback).toEqual(dastFeedbacks[1]);
    });

    it('parses dast report', () => {
      expect(parseDastIssues(multiSitesDast.site)).toEqual(parsedMultiSitesDast);
    });

    it('parses legacy dast report', () => {
      expect(parseDastIssues(dast.site)).toEqual(parsedDast);
    });
  });

  describe('filterByKey', () => {
    it('filters the array with the provided key', () => {
      const array1 = [{ id: '1234' }, { id: 'abg543' }, { id: '214swfA' }];
      const array2 = [{ id: '1234' }, { id: 'abg543' }, { id: '453OJKs' }];

      expect(filterByKey(array1, array2, 'id')).toEqual([{ id: '214swfA' }]);
    });
  });

  describe('getFileLocation', () => {
    const hostname = 'https://hostna.me';
    const path = '/deeply/nested/route';

    it('should return the correct location when passed both a hostname and a path', () => {
      const result = getFileLocation({ hostname, path });

      expect(result).toEqual(`${hostname}${path}`);
    });

    it('should return null if the hostname is not present', () => {
      const result = getFileLocation({ path });

      expect(result).toBeNull();
    });

    it('should return null if the path is not present', () => {
      const result = getFileLocation({ hostname });

      expect(result).toBeNull();
    });

    it('should return null if the argument is undefined', () => {
      const result = getFileLocation(undefined);

      expect(result).toBeNull();
    });
  });

  describe('getUnapprovedVulnerabilities', () => {
    it('return unapproved vulnerabilities', () => {
      const unapproved = getUnapprovedVulnerabilities(
        dockerReport.vulnerabilities,
        dockerReport.unapproved,
      );

      expect(unapproved.length).toEqual(dockerReport.unapproved.length);
      expect(unapproved[0].vulnerability).toEqual(dockerReport.unapproved[0]);
      expect(unapproved[1].vulnerability).toEqual(dockerReport.unapproved[1]);
    });
  });

  describe('textBuilder', () => {
    describe('with only the head', () => {
      const paths = { head: 'foo' };

      it('should return unable to compare text', () => {
        expect(groupedTextBuilder({ paths, added: 1 })).toEqual(
          ' detected 1 vulnerability for the source branch only',
        );
      });

      it('should return unable to compare text with no vulnerability', () => {
        expect(groupedTextBuilder({ paths })).toEqual(
          ' detected no vulnerabilities for the source branch only',
        );
      });

      it('should return dismissed text', () => {
        expect(groupedTextBuilder({ paths, dismissed: 2 })).toEqual(
          ' detected 2 dismissed vulnerabilities for the source branch only',
        );
      });

      it('should return new and dismissed text', () => {
        expect(groupedTextBuilder({ paths, added: 1, dismissed: 2 })).toEqual(
          ' detected 1 new, and 2 dismissed vulnerabilities for the source branch only',
        );
      });
    });

    describe('with base and head', () => {
      const paths = { head: 'foo', base: 'foo' };

      describe('with no issues', () => {
        it('should return no vulnerabiltities text', () => {
          expect(groupedTextBuilder({ paths })).toEqual(' detected no vulnerabilities');
        });
      });

      describe('with only `all` issues', () => {
        it('should return no new vulnerabiltities text', () => {
          expect(groupedTextBuilder({ paths, existing: 1 })).toEqual(
            ' detected no new vulnerabilities',
          );
        });
      });

      describe('with only new issues', () => {
        it('should return new issues text', () => {
          expect(groupedTextBuilder({ paths, added: 1 })).toEqual(' detected 1 new vulnerability');

          expect(groupedTextBuilder({ paths, added: 2 })).toEqual(
            ' detected 2 new vulnerabilities',
          );
        });
      });

      describe('with new and resolved issues', () => {
        it('should return new and fixed issues text', () => {
          expect(groupedTextBuilder({ paths, added: 1, fixed: 1 }).replace(/\n+\s+/m, ' ')).toEqual(
            ' detected 1 new, and 1 fixed vulnerabilities',
          );

          expect(groupedTextBuilder({ paths, added: 2, fixed: 2 }).replace(/\n+\s+/m, ' ')).toEqual(
            ' detected 2 new, and 2 fixed vulnerabilities',
          );
        });
      });

      describe('with only resolved issues', () => {
        it('should return fixed issues text', () => {
          expect(groupedTextBuilder({ paths, fixed: 1 })).toEqual(
            ' detected 1 fixed vulnerability',
          );

          expect(groupedTextBuilder({ paths, fixed: 2 })).toEqual(
            ' detected 2 fixed vulnerabilities',
          );
        });
      });

      describe('with dismissed issues', () => {
        it('should return dismissed text', () => {
          expect(groupedTextBuilder({ paths, dismissed: 2 })).toEqual(
            ' detected 2 dismissed vulnerabilities',
          );
        });

        it('should return new and dismissed text', () => {
          expect(groupedTextBuilder({ paths, added: 1, dismissed: 2 })).toEqual(
            ' detected 1 new, and 2 dismissed vulnerabilities',
          );
        });

        it('should return fixed and dismissed text', () => {
          expect(groupedTextBuilder({ paths, fixed: 1, dismissed: 2 })).toEqual(
            ' detected 1 fixed, and 2 dismissed vulnerabilities',
          );
        });

        it('should return new, fixed and dismissed text', () => {
          expect(groupedTextBuilder({ paths, fixed: 1, added: 1, dismissed: 2 })).toEqual(
            ' detected 1 new, 1 fixed, and 2 dismissed vulnerabilities',
          );
        });
      });
    });
  });

  describe('statusIcon', () => {
    describe('with failed report', () => {
      it('returns warning', () => {
        expect(statusIcon(false, true)).toEqual('warning');
      });
    });

    describe('with new issues', () => {
      it('returns warning', () => {
        expect(statusIcon(false, false, 1)).toEqual('warning');
      });
    });

    describe('with neutral issues', () => {
      it('returns warning', () => {
        expect(statusIcon(false, false, 0, 1)).toEqual('warning');
      });
    });

    describe('without new or neutal issues', () => {
      it('returns success', () => {
        expect(statusIcon()).toEqual('success');
      });
    });
  });

  describe('countIssues', () => {
    const allIssues = [{}];
    const resolvedIssues = [{}];
    const dismissedIssues = [{ isDismissed: true }];
    const addedIssues = [{ isDismissed: false }];

    it('returns 0 for all counts if everything is empty', () => {
      expect(countIssues()).toEqual({
        added: 0,
        dismissed: 0,
        existing: 0,
        fixed: 0,
      });
    });

    it('counts `allIssues` as existing', () => {
      expect(countIssues({ allIssues })).toEqual({
        added: 0,
        dismissed: 0,
        existing: 1,
        fixed: 0,
      });
    });

    it('counts `resolvedIssues` as fixed', () => {
      expect(countIssues({ resolvedIssues })).toEqual({
        added: 0,
        dismissed: 0,
        existing: 0,
        fixed: 1,
      });
    });

    it('counts `newIssues` which are dismissed as dismissed', () => {
      expect(countIssues({ newIssues: dismissedIssues })).toEqual({
        added: 0,
        dismissed: 1,
        existing: 0,
        fixed: 0,
      });
    });

    it('counts `newIssues` which are not dismissed as added', () => {
      expect(countIssues({ newIssues: addedIssues })).toEqual({
        added: 1,
        dismissed: 0,
        existing: 0,
        fixed: 0,
      });
    });

    it('counts everything', () => {
      expect(
        countIssues({ newIssues: [...addedIssues, ...dismissedIssues], resolvedIssues, allIssues }),
      ).toEqual({
        added: 1,
        dismissed: 1,
        existing: 1,
        fixed: 1,
      });
    });
  });

  describe('groupedReportText', () => {
    const reportType = 'dummyReport';
    const errorMessage = 'Something went wrong';
    const loadingMessage = 'The report is still loading';
    const baseReport = { paths: [] };

    it("should return the error message when there's an error", () => {
      const report = { ...baseReport, hasError: true };
      const result = groupedReportText(report, reportType, errorMessage, loadingMessage);

      expect(result).toBe(errorMessage);
    });

    it("should return the loading message when it's loading", () => {
      const report = { ...baseReport, isLoading: true };
      const result = groupedReportText(report, reportType, errorMessage, loadingMessage);

      expect(result).toBe(loadingMessage);
    });

    it("should call groupedTextBuilder if it isn't loading and doesn't have an error", () => {
      const report = { ...baseReport };
      const result = groupedReportText(report, reportType, errorMessage, loadingMessage);

      expect(result).toBe(`${reportType} detected no vulnerabilities for the source branch only`);
    });
  });
});
