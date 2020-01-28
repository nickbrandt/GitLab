import state from 'ee/vue_shared/security_reports/store/state';
import mutations from 'ee/vue_shared/security_reports/store/mutations';
import * as types from 'ee/vue_shared/security_reports/store/mutation_types';
import { mockFindings } from '../mock_data';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

describe('security reports mutations', () => {
  let stateCopy;

  beforeEach(() => {
    stateCopy = state();
  });

  describe('SET_HEAD_BLOB_PATH', () => {
    it('should set head blob path', () => {
      mutations[types.SET_HEAD_BLOB_PATH](stateCopy, 'head_blob_path');

      expect(stateCopy.blobPath.head).toEqual('head_blob_path');
    });
  });

  describe('SET_BASE_BLOB_PATH', () => {
    it('should set base blob path', () => {
      mutations[types.SET_BASE_BLOB_PATH](stateCopy, 'base_blob_path');

      expect(stateCopy.blobPath.base).toEqual('base_blob_path');
    });
  });

  describe('SET_VULNERABILITY_FEEDBACK_PATH', () => {
    it('should set the vulnerabilities endpoint', () => {
      mutations[types.SET_VULNERABILITY_FEEDBACK_PATH](stateCopy, 'vulnerability_path');

      expect(stateCopy.vulnerabilityFeedbackPath).toEqual('vulnerability_path');
    });
  });

  describe('SET_VULNERABILITY_FEEDBACK_HELP_PATH', () => {
    it('should set the vulnerabilities help path', () => {
      mutations[types.SET_VULNERABILITY_FEEDBACK_HELP_PATH](stateCopy, 'vulnerability_help_path');

      expect(stateCopy.vulnerabilityFeedbackHelpPath).toEqual('vulnerability_help_path');
    });
  });

  describe('SET_PIPELINE_ID', () => {
    it('should set the pipeline id', () => {
      mutations[types.SET_PIPELINE_ID](stateCopy, 123);

      expect(stateCopy.pipelineId).toEqual(123);
    });
  });

  describe('SET_CAN_CREATE_ISSUE_PERMISSION', () => {
    it('should set permission for create issue', () => {
      mutations[types.SET_CAN_CREATE_ISSUE_PERMISSION](stateCopy, true);

      expect(stateCopy.canCreateIssuePermission).toEqual(true);
    });
  });

  describe('SET_CAN_CREATE_FEEDBACK_PERMISSION', () => {
    it('should set permission for create feedback', () => {
      mutations[types.SET_CAN_CREATE_FEEDBACK_PERMISSION](stateCopy, true);

      expect(stateCopy.canCreateFeedbackPermission).toEqual(true);
    });
  });

  describe('REQUEST_CONTAINER_SCANNING_DIFF', () => {
    it('should set container scanning loading flag to true', () => {
      mutations[types.REQUEST_CONTAINER_SCANNING_DIFF](stateCopy);

      expect(stateCopy.containerScanning.isLoading).toEqual(true);
    });
  });

  describe('REQUEST_DAST_DIFF', () => {
    it('should set dast loading flag to true', () => {
      mutations[types.REQUEST_DAST_DIFF](stateCopy);

      expect(stateCopy.dast.isLoading).toEqual(true);
    });
  });

  describe('REQUEST_DEPENDENCY_SCANNING_DIFF', () => {
    it('should set dependency scanning loading flag to true', () => {
      mutations[types.REQUEST_DEPENDENCY_SCANNING_DIFF](stateCopy);

      expect(stateCopy.dependencyScanning.isLoading).toEqual(true);
    });
  });

  describe('SET_ISSUE_MODAL_DATA', () => {
    it('has default data', () => {
      expect(stateCopy.modal.data.description.value).toEqual(null);
      expect(stateCopy.modal.data.description.text).toEqual('Description');
      expect(stateCopy.modal.data.description.isLink).toEqual(false);

      expect(stateCopy.modal.data.identifiers.value).toEqual([]);
      expect(stateCopy.modal.data.identifiers.text).toEqual('Identifiers');
      expect(stateCopy.modal.data.identifiers.isLink).toEqual(false);

      expect(stateCopy.modal.data.file.value).toEqual(null);
      expect(stateCopy.modal.data.file.text).toEqual('File');
      expect(stateCopy.modal.data.file.isLink).toEqual(true);

      expect(stateCopy.modal.data.className.value).toEqual(null);
      expect(stateCopy.modal.data.className.text).toEqual('Class');
      expect(stateCopy.modal.data.className.isLink).toEqual(false);

      expect(stateCopy.modal.data.methodName.value).toEqual(null);
      expect(stateCopy.modal.data.methodName.text).toEqual('Method');
      expect(stateCopy.modal.data.methodName.isLink).toEqual(false);

      expect(stateCopy.modal.data.namespace.value).toEqual(null);
      expect(stateCopy.modal.data.namespace.text).toEqual('Namespace');
      expect(stateCopy.modal.data.namespace.isLink).toEqual(false);

      expect(stateCopy.modal.data.severity.value).toEqual(null);
      expect(stateCopy.modal.data.severity.text).toEqual('Severity');
      expect(stateCopy.modal.data.severity.isLink).toEqual(false);

      expect(stateCopy.modal.data.confidence.value).toEqual(null);
      expect(stateCopy.modal.data.confidence.text).toEqual('Confidence');
      expect(stateCopy.modal.data.confidence.isLink).toEqual(false);

      expect(stateCopy.modal.data.links.value).toEqual([]);
      expect(stateCopy.modal.data.links.text).toEqual('Links');
      expect(stateCopy.modal.data.links.isLink).toEqual(false);

      expect(stateCopy.modal.data.instances.value).toEqual([]);
      expect(stateCopy.modal.data.instances.text).toEqual('Instances');
      expect(stateCopy.modal.data.instances.isLink).toEqual(false);

      expect(stateCopy.modal.vulnerability.isDismissed).toEqual(false);
      expect(stateCopy.modal.vulnerability.hasIssue).toEqual(false);

      expect(stateCopy.modal.isCreatingNewIssue).toEqual(false);
      expect(stateCopy.modal.isDismissingVulnerability).toEqual(false);

      expect(stateCopy.modal.data.url.value).toEqual(null);
      expect(stateCopy.modal.data.url.url).toEqual(null);

      expect(stateCopy.modal.title).toEqual(null);
      expect(stateCopy.modal.learnMoreUrl).toEqual(null);
      expect(stateCopy.modal.error).toEqual(null);
    });

    it('sets modal data', () => {
      stateCopy.vulnerabilityFeedbackPath = 'path';

      const issue = {
        tool: 'bundler_audit',
        message: 'Arbitrary file existence disclosure in Action Pack',
        cve: 'CVE-2014-7829',
        solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
        title: 'Arbitrary file existence disclosure in Action Pack',
        path: 'Gemfile.lock',
        urlPath: 'path/Gemfile.lock',
        location: {
          file: 'Gemfile.lock',
          class: 'User',
          method: 'do_something',
          image: 'https://example.org/docker/example:v1.2.3',
          operating_system: 'debian:8',
          hostname: 'https://gitlab.com',
          path: '/user6',
        },
        links: [
          {
            url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
          },
        ],
        identifiers: [
          {
            type: 'CVE',
            name: 'CVE-2014-9999',
            value: 'CVE-2014-9999',
            url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-9999',
          },
        ],
        instances: [
          {
            param: 'X-Content-Type-Options',
            method: 'GET',
            uri: 'http://example.com/some-path',
          },
        ],
        isDismissed: true,
      };
      const status = 'success';

      mutations[types.SET_ISSUE_MODAL_DATA](stateCopy, { issue, status });

      expect(stateCopy.modal.title).toEqual(issue.title);
      expect(stateCopy.modal.data.description.value).toEqual(issue.description);
      expect(stateCopy.modal.data.file.value).toEqual(issue.location.file);
      expect(stateCopy.modal.data.file.url).toEqual(issue.urlPath);
      expect(stateCopy.modal.data.className.value).toEqual(issue.location.class);
      expect(stateCopy.modal.data.methodName.value).toEqual(issue.location.method);
      expect(stateCopy.modal.data.namespace.value).toEqual(issue.location.operating_system);
      expect(stateCopy.modal.data.image.value).toEqual(issue.location.image);
      expect(stateCopy.modal.data.identifiers.value).toEqual(issue.identifiers);
      expect(stateCopy.modal.data.severity.value).toEqual(issue.severity);
      expect(stateCopy.modal.data.confidence.value).toEqual(issue.confidence);
      expect(stateCopy.modal.data.links.value).toEqual(issue.links);
      expect(stateCopy.modal.data.instances.value).toEqual(issue.instances);
      expect(stateCopy.modal.data.url.value).toEqual(
        `${issue.location.hostname}${issue.location.path}`,
      );
      expect(stateCopy.modal.data.url.url).toEqual(
        `${issue.location.hostname}${issue.location.path}`,
      );
      expect(stateCopy.modal.vulnerability).toEqual(issue);
      expect(stateCopy.modal.isResolved).toEqual(true);
    });
  });

  describe('REQUEST_DISMISS_VULNERABILITY', () => {
    it('sets isDismissingVulnerability prop to true and resets error', () => {
      mutations[types.REQUEST_DISMISS_VULNERABILITY](stateCopy);

      expect(stateCopy.modal.isDismissingVulnerability).toEqual(true);
      expect(stateCopy.modal.error).toBeNull();
    });
  });

  describe('RECEIVE_DISMISS_VULNERABILITY_SUCCESS', () => {
    it('sets isDismissingVulnerability prop to false', () => {
      mutations[types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS](stateCopy);

      expect(stateCopy.modal.isDismissingVulnerability).toEqual(false);
    });
  });

  describe('RECEIVE_DISMISS_VULNERABILITY_ERROR', () => {
    it('sets isDismissingVulnerability prop to false and sets error', () => {
      mutations[types.RECEIVE_DISMISS_VULNERABILITY_ERROR](stateCopy, 'error');

      expect(stateCopy.modal.isDismissingVulnerability).toEqual(false);
      expect(stateCopy.modal.error).toEqual('error');
    });
  });

  describe(types.REQUEST_ADD_DISMISSAL_COMMENT, () => {
    beforeEach(() => {
      mutations[types.REQUEST_ADD_DISMISSAL_COMMENT](stateCopy);
    });

    it('should set isDismissingVulnerability to true', () => {
      expect(stateCopy.isDismissingVulnerability).toBe(true);
    });

    it('should set isDismissingVulnerability in the modal data to true', () => {
      expect(stateCopy.modal.isDismissingVulnerability).toBe(true);
    });

    it('should nullify the error state on the modal', () => {
      expect(stateCopy.modal.error).toBeNull();
    });
  });

  describe(types.RECEIVE_ADD_DISMISSAL_COMMENT_SUCCESS, () => {
    let payload;
    let vulnerability;
    let data;

    beforeEach(() => {
      vulnerability = { id: 1 };
      data = { name: 'dismissal feedback' };
      payload = { id: vulnerability.id, data };
      mutations[types.RECEIVE_ADD_DISMISSAL_COMMENT_SUCCESS](stateCopy, payload);
    });

    it('should set isDismissingVulnerability to false', () => {
      expect(stateCopy.isDismissingVulnerability).toBe(false);
    });

    it('should set isDismissingVulnerability on the modal to false', () => {
      expect(stateCopy.modal.isDismissingVulnerability).toBe(false);
    });

    it('shoulfd set isDissmissed on the modal vulnerability to be true', () => {
      expect(stateCopy.modal.vulnerability.isDismissed).toBe(true);
    });
  });

  describe(types.RECEIVE_ADD_DISMISSAL_COMMENT_ERROR, () => {
    const error = 'There was an error adding the comment.';

    beforeEach(() => {
      mutations[types.RECEIVE_ADD_DISMISSAL_COMMENT_ERROR](stateCopy, error);
    });

    it('should set isDismissingVulnerability to false', () => {
      expect(stateCopy.isDismissingVulnerability).toBe(false);
    });

    it('should set isDismissingVulnerability in the modal data to false', () => {
      expect(stateCopy.modal.isDismissingVulnerability).toBe(false);
    });

    it('should set the error state on the modal', () => {
      expect(stateCopy.modal.error).toEqual(error);
    });
  });

  describe(types.REQUEST_DELETE_DISMISSAL_COMMENT, () => {
    beforeEach(() => {
      mutations[types.REQUEST_DELETE_DISMISSAL_COMMENT](stateCopy);
    });

    it('should set isDismissingVulnerability to true', () => {
      expect(stateCopy.isDismissingVulnerability).toBe(true);
    });

    it('should set isDismissingVulnerability in the modal data to true', () => {
      expect(stateCopy.modal.isDismissingVulnerability).toBe(true);
    });

    it('should nullify the error state on the modal', () => {
      expect(stateCopy.modal.error).toBeNull();
    });
  });

  describe(types.RECEIVE_DELETE_DISMISSAL_COMMENT_SUCCESS, () => {
    let payload;
    let vulnerability;
    let data;

    beforeEach(() => {
      vulnerability = { id: 1 };
      data = { name: 'dismissal feedback' };
      payload = { id: vulnerability.id, data };
      mutations[types.RECEIVE_DELETE_DISMISSAL_COMMENT_SUCCESS](stateCopy, payload);
    });

    it('should set isDismissingVulnerability to false', () => {
      expect(stateCopy.isDismissingVulnerability).toBe(false);
    });

    it('should set isDismissingVulnerability on the modal to false', () => {
      expect(stateCopy.modal.isDismissingVulnerability).toBe(false);
    });

    it('shoulfd set isDissmissed on the modal vulnerability to be true', () => {
      expect(stateCopy.modal.vulnerability.isDismissed).toBe(true);
    });
  });

  describe(types.RECEIVE_DELETE_DISMISSAL_COMMENT_ERROR, () => {
    const error = 'There was an error deleting the comment.';

    beforeEach(() => {
      mutations[types.RECEIVE_DELETE_DISMISSAL_COMMENT_ERROR](stateCopy, error);
    });

    it('should set isDismissingVulnerability to false', () => {
      expect(stateCopy.isDismissingVulnerability).toBe(false);
    });

    it('should set isDismissingVulnerability in the modal data to false', () => {
      expect(stateCopy.modal.isDismissingVulnerability).toBe(false);
    });

    it('should set the error state on the modal', () => {
      expect(stateCopy.modal.error).toEqual(error);
    });
  });

  describe(types.SHOW_DISMISSAL_DELETE_BUTTONS, () => {
    beforeEach(() => {
      mutations[types.SHOW_DISMISSAL_DELETE_BUTTONS](stateCopy);
    });

    it('should set isShowingDeleteButtonsto to true', () => {
      expect(stateCopy.modal.isShowingDeleteButtons).toBe(true);
    });
  });

  describe(types.HIDE_DISMISSAL_DELETE_BUTTONS, () => {
    beforeEach(() => {
      mutations[types.HIDE_DISMISSAL_DELETE_BUTTONS](stateCopy);
    });

    it('should set isShowingDeleteButtons to false', () => {
      expect(stateCopy.modal.isShowingDeleteButtons).toBe(false);
    });
  });

  describe('OPEN_DISMISSAL_COMMENT_BOX', () => {
    beforeEach(() => {
      mutations[types.OPEN_DISMISSAL_COMMENT_BOX](stateCopy);
    });

    it('should set isCommentingOnDismissal to true', () => {
      expect(stateCopy.modal.isCommentingOnDismissal).toBe(true);
    });
  });

  describe('CLOSE_DISMISSAL_COMMENT_BOX', () => {
    beforeEach(() => {
      mutations[types.CLOSE_DISMISSAL_COMMENT_BOX](stateCopy);
    });

    it('should set isCommentingOnDismissal to false', () => {
      expect(stateCopy.modal.isCommentingOnDismissal).toBe(false);
    });

    it('should set isShowingDeleteButtons to false', () => {
      expect(stateCopy.modal.isShowingDeleteButtons).toBe(false);
    });
  });

  describe('REQUEST_CREATE_ISSUE', () => {
    it('sets isCreatingNewIssue prop to true and resets error', () => {
      mutations[types.REQUEST_CREATE_ISSUE](stateCopy);

      expect(stateCopy.modal.isCreatingNewIssue).toEqual(true);
      expect(stateCopy.modal.error).toBeNull();
    });
  });

  describe('RECEIVE_CREATE_ISSUE_SUCCESS', () => {
    it('sets isCreatingNewIssue prop to false', () => {
      mutations[types.RECEIVE_CREATE_ISSUE_SUCCESS](stateCopy);

      expect(stateCopy.modal.isCreatingNewIssue).toEqual(false);
    });
  });

  describe('RECEIVE_CREATE_ISSUE_ERROR', () => {
    it('sets isCreatingNewIssue prop to false and sets error', () => {
      mutations[types.RECEIVE_CREATE_ISSUE_ERROR](stateCopy, 'error');

      expect(stateCopy.modal.isCreatingNewIssue).toEqual(false);
      expect(stateCopy.modal.error).toEqual('error');
    });
  });

  describe('REQUEST_CREATE_MERGE_REQUEST', () => {
    it('sets isCreatingMergeRequest prop to true and resets error', () => {
      mutations[types.REQUEST_CREATE_MERGE_REQUEST](stateCopy);

      expect(stateCopy.modal.isCreatingMergeRequest).toEqual(true);
      expect(stateCopy.modal.error).toBeNull();
    });
  });

  describe('RECEIVE_CREATE_MERGE_REQUEST_SUCCESS', () => {
    it('should fire the visitUrl function on the merge request URL', () => {
      const payload = { merge_request_path: 'fakepath.html' };
      mutations[types.RECEIVE_CREATE_MERGE_REQUEST_SUCCESS](stateCopy, payload);

      expect(visitUrl).toHaveBeenCalledWith(payload.merge_request_path);
    });
  });

  describe('RECEIVE_CREATE_MERGE_REQUEST_ERROR', () => {
    it('sets isCreatingMergeRequest prop to false and sets error', () => {
      mutations[types.RECEIVE_CREATE_MERGE_REQUEST_ERROR](stateCopy, 'error');

      expect(stateCopy.modal.isCreatingMergeRequest).toEqual(false);
      expect(stateCopy.modal.error).toEqual('error');
    });
  });

  describe('UPDATE_DEPENDENCY_SCANNING_ISSUE', () => {
    it('updates issue in the new issues list', () => {
      stateCopy.dependencyScanning.newIssues = mockFindings;
      stateCopy.dependencyScanning.resolvedIssues = [];
      stateCopy.dependencyScanning.allIssues = [];
      const updatedIssue = {
        ...mockFindings[0],
        foo: 'bar',
      };

      mutations[types.UPDATE_DEPENDENCY_SCANNING_ISSUE](stateCopy, updatedIssue);

      expect(stateCopy.dependencyScanning.newIssues[0]).toEqual(updatedIssue);
    });

    it('updates issue in the resolved issues list', () => {
      stateCopy.dependencyScanning.newIssues = [];
      stateCopy.dependencyScanning.resolvedIssues = mockFindings;
      stateCopy.dependencyScanning.allIssues = [];
      const updatedIssue = {
        ...mockFindings[0],
        foo: 'bar',
      };

      mutations[types.UPDATE_DEPENDENCY_SCANNING_ISSUE](stateCopy, updatedIssue);

      expect(stateCopy.dependencyScanning.resolvedIssues[0]).toEqual(updatedIssue);
    });

    it('updates issue in the all issues list', () => {
      stateCopy.dependencyScanning.newIssues = [];
      stateCopy.dependencyScanning.resolvedIssues = [];
      stateCopy.dependencyScanning.allIssues = mockFindings;
      const updatedIssue = {
        ...mockFindings[0],
        foo: 'bar',
      };

      mutations[types.UPDATE_DEPENDENCY_SCANNING_ISSUE](stateCopy, updatedIssue);

      expect(stateCopy.dependencyScanning.allIssues[0]).toEqual(updatedIssue);
    });
  });

  describe('UPDATE_CONTAINER_SCANNING_ISSUE', () => {
    it('updates issue in the new issues list', () => {
      stateCopy.containerScanning.newIssues = mockFindings;
      stateCopy.containerScanning.resolvedIssues = [];
      const updatedIssue = {
        ...mockFindings[0],
        foo: 'bar',
      };

      mutations[types.UPDATE_CONTAINER_SCANNING_ISSUE](stateCopy, updatedIssue);

      expect(stateCopy.containerScanning.newIssues[0]).toEqual(updatedIssue);
    });

    it('updates issue in the resolved issues list', () => {
      stateCopy.containerScanning.newIssues = [];
      stateCopy.containerScanning.resolvedIssues = mockFindings;
      const updatedIssue = {
        ...mockFindings[0],
        foo: 'bar',
      };

      mutations[types.UPDATE_CONTAINER_SCANNING_ISSUE](stateCopy, updatedIssue);

      expect(stateCopy.containerScanning.resolvedIssues[0]).toEqual(updatedIssue);
    });
  });

  describe('UPDATE_DAST_ISSUE', () => {
    it('updates issue in the new issues list', () => {
      stateCopy.dast.newIssues = mockFindings;
      stateCopy.dast.resolvedIssues = [];
      const updatedIssue = {
        ...mockFindings[0],
        foo: 'bar',
      };

      mutations[types.UPDATE_DAST_ISSUE](stateCopy, updatedIssue);

      expect(stateCopy.dast.newIssues[0]).toEqual(updatedIssue);
    });

    it('updates issue in the resolved issues list', () => {
      stateCopy.dast.newIssues = [];
      stateCopy.dast.resolvedIssues = mockFindings;
      const updatedIssue = {
        ...mockFindings[0],
        foo: 'bar',
      };

      mutations[types.UPDATE_DAST_ISSUE](stateCopy, updatedIssue);

      expect(stateCopy.dast.resolvedIssues[0]).toEqual(updatedIssue);
    });
  });

  describe('SET_CONTAINER_SCANNING_DIFF_ENDPOINT', () => {
    const endpoint = 'container_scanning_diff_endpoint.json';

    beforeEach(() => {
      mutations[types.SET_CONTAINER_SCANNING_DIFF_ENDPOINT](stateCopy, endpoint);
    });

    it('should set the correct endpoint', () => {
      expect(stateCopy.containerScanning.paths.diffEndpoint).toEqual(endpoint);
    });
  });

  describe('RECEIVE_CONTAINER_SCANNING_DIFF_SUCCESS', () => {
    const reports = {
      diff: {
        added: [
          { name: 'added vuln 1', report_type: 'container_scanning' },
          { name: 'added vuln 2', report_type: 'container_scanning' },
        ],
        fixed: [{ name: 'fixed vuln 1', report_type: 'container_scanning' }],
        base_report_out_of_date: true,
      },
    };

    beforeEach(() => {
      mutations[types.RECEIVE_CONTAINER_SCANNING_DIFF_SUCCESS](stateCopy, reports);
    });

    it('should set isLoading to false', () => {
      expect(stateCopy.containerScanning.isLoading).toBe(false);
    });

    it('should set baseReportOutofDate to true', () => {
      expect(stateCopy.containerScanning.baseReportOutofDate).toBe(true);
    });

    it('should parse and set the added vulnerabilities', () => {
      reports.diff.added.forEach((vuln, i) => {
        expect(stateCopy.containerScanning.newIssues[i]).toEqual(
          expect.objectContaining({
            name: vuln.name,
            title: vuln.name,
            category: vuln.report_type,
          }),
        );
      });
    });

    it('should parse and set the fixed vulnerabilities', () => {
      reports.diff.fixed.forEach((vuln, i) => {
        expect(stateCopy.containerScanning.resolvedIssues[i]).toEqual(
          expect.objectContaining({
            name: vuln.name,
            title: vuln.name,
            category: vuln.report_type,
          }),
        );
      });
    });
  });

  describe('RECEIVE_CONTAINER_SCANNING_DIFF_ERROR', () => {
    it('should set container scanning loading flag to false and error flag to true', () => {
      mutations[types.RECEIVE_CONTAINER_SCANNING_DIFF_ERROR](stateCopy);

      expect(stateCopy.containerScanning.isLoading).toEqual(false);
      expect(stateCopy.containerScanning.hasError).toEqual(true);
    });
  });

  describe('SET_DEPENDENCY_SCANNING_DIFF_ENDPOINT', () => {
    const endpoint = 'dependency_scannning_diff_endpoint.json';

    beforeEach(() => {
      mutations[types.SET_DEPENDENCY_SCANNING_DIFF_ENDPOINT](stateCopy, endpoint);
    });

    it('should set the correct endpoint', () => {
      expect(stateCopy.dependencyScanning.paths.diffEndpoint).toEqual(endpoint);
    });
  });

  describe('RECEIVE_DEPENDENCY_SCANNING_DIFF_SUCCESS', () => {
    let reports = {};

    beforeEach(() => {
      reports = {
        diff: {
          added: [
            { name: 'added vuln 1', report_type: 'dependency_scanning' },
            { name: 'added vuln 2', report_type: 'dependency_scanning' },
          ],
          fixed: [{ name: 'fixed vuln 1', report_type: 'dependency_scanning' }],
          existing: [{ name: 'existing vuln 1', report_type: 'dependency_scanning' }],
          base_report_out_of_date: true,
        },
      };
      mutations[types.RECEIVE_DEPENDENCY_SCANNING_DIFF_SUCCESS](stateCopy, reports);
    });

    it('should set isLoading to false', () => {
      expect(stateCopy.dependencyScanning.isLoading).toBe(false);
    });

    it('should set baseReportOutofDate to true', () => {
      expect(stateCopy.dependencyScanning.baseReportOutofDate).toBe(true);
    });

    it('should parse and set the added vulnerabilities', () => {
      reports.diff.added.forEach((vuln, i) => {
        expect(stateCopy.dependencyScanning.newIssues[i]).toEqual(
          expect.objectContaining({
            name: vuln.name,
            title: vuln.name,
            category: vuln.report_type,
          }),
        );
      });
    });

    it('should parse and set the fixed vulnerabilities', () => {
      reports.diff.fixed.forEach((vuln, i) => {
        expect(stateCopy.dependencyScanning.resolvedIssues[i]).toEqual(
          expect.objectContaining({
            name: vuln.name,
            title: vuln.name,
            category: vuln.report_type,
          }),
        );
      });
    });
  });

  describe('RECEIVE_DEPENDENCY_SCANNING_DIFF_ERROR', () => {
    it('should set dependency scanning loading flag to false and error flag to true', () => {
      mutations[types.RECEIVE_DEPENDENCY_SCANNING_DIFF_ERROR](stateCopy);

      expect(stateCopy.dependencyScanning.isLoading).toEqual(false);
      expect(stateCopy.dependencyScanning.hasError).toEqual(true);
    });
  });

  describe('SET_DAST_DIFF_ENDPOINT', () => {
    const endpoint = 'dast_diff_endpoint.json';

    beforeEach(() => {
      mutations[types.SET_DAST_DIFF_ENDPOINT](stateCopy, endpoint);
    });

    it('should set the correct endpoint', () => {
      expect(stateCopy.dast.paths.diffEndpoint).toEqual(endpoint);
    });
  });

  describe('RECEIVE_DAST_DIFF_SUCCESS', () => {
    let reports = {};

    beforeEach(() => {
      reports = {
        diff: {
          added: [
            { name: 'added vuln 1', report_type: 'dast' },
            { name: 'added vuln 2', report_type: 'dast' },
          ],
          fixed: [{ name: 'fixed vuln 1', report_type: 'dast' }],
          existing: [{ name: 'existing vuln 1', report_type: 'dast' }],
          base_report_out_of_date: true,
        },
      };
      mutations[types.RECEIVE_DAST_DIFF_SUCCESS](stateCopy, reports);
    });

    it('should set isLoading to false', () => {
      expect(stateCopy.dast.isLoading).toBe(false);
    });

    it('should set baseReportOutofDate to true', () => {
      expect(stateCopy.dast.baseReportOutofDate).toBe(true);
    });

    it('should parse and set the added vulnerabilities', () => {
      reports.diff.added.forEach((vuln, i) => {
        expect(stateCopy.dast.newIssues[i]).toEqual(
          expect.objectContaining({
            name: vuln.name,
            title: vuln.name,
            category: vuln.report_type,
          }),
        );
      });
    });

    it('should parse and set the fixed vulnerabilities', () => {
      reports.diff.fixed.forEach((vuln, i) => {
        expect(stateCopy.dast.resolvedIssues[i]).toEqual(
          expect.objectContaining({
            name: vuln.name,
            title: vuln.name,
            category: vuln.report_type,
          }),
        );
      });
    });
  });

  describe('RECEIVE_DAST_DIFF_ERROR', () => {
    it('should set dast loading flag to false and error flag to true', () => {
      mutations[types.RECEIVE_DAST_DIFF_ERROR](stateCopy);

      expect(stateCopy.dast.isLoading).toEqual(false);
      expect(stateCopy.dast.hasError).toEqual(true);
    });
  });
});
