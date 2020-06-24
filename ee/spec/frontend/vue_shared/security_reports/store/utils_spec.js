import {
  findIssueIndex,
  groupedTextBuilder,
  statusIcon,
  countIssues,
  groupedReportText,
} from 'ee/vue_shared/security_reports/store/utils';
import filterByKey from 'ee/vue_shared/security_reports/store/utils/filter_by_key';
import getFileLocation from 'ee/vue_shared/security_reports/store/utils/get_file_location';
import getPrimaryIdentifiers from 'ee/vue_shared/security_reports/store/utils/get_primary_identifier';

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

  describe('getPrimaryIdentifier', () => {
    const identifiers = [
      { external_type: 'cve', name: 'CVE-1337' },
      { external_type: 'gemnaisum', name: 'GEMNASIUM-1337' },
    ];
    it('should return the `cve` identifier if a `cve` identifier does exist', () => {
      expect(getPrimaryIdentifiers(identifiers)).toBe(identifiers[0].name);
    });
    it('should return the first identifier if a `cve` identifier does not exist', () => {
      expect(getPrimaryIdentifiers([identifiers[1]])).toBe(identifiers[1].name);
    });
    it('should return an empty string if identifiers is empty', () => {
      expect(getPrimaryIdentifiers()).toBe('');
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
