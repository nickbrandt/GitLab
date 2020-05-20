import { n__, s__, sprintf } from '~/locale';

/**
 * Returns the index of an issue in given list
 * @param {Array} issues
 * @param {Object} issue
 */
export const findIssueIndex = (issues, issue) =>
  issues.findIndex(el => el.project_fingerprint === issue.project_fingerprint);

/**
 * Returns given vulnerability enriched with the corresponding
 * feedback (`dismissal` or `issue` type)
 * @param {Object} vulnerability
 * @param {Array} feedback
 */
export const enrichVulnerabilityWithFeedback = (vulnerability, feedback = []) =>
  feedback
    .filter(fb => fb.project_fingerprint === vulnerability.project_fingerprint)
    .reduce((vuln, fb) => {
      if (fb.feedback_type === 'dismissal') {
        return {
          ...vuln,
          isDismissed: true,
          dismissalFeedback: fb,
        };
      }
      if (fb.feedback_type === 'issue' && fb.issue_iid) {
        return {
          ...vuln,
          hasIssue: true,
          issue_feedback: fb,
        };
      }
      if (fb.feedback_type === 'merge_request' && fb.merge_request_iid) {
        return {
          ...vuln,
          hasMergeRequest: true,
          merge_request_feedback: fb,
        };
      }
      return vuln;
    }, vulnerability);

export const groupedTextBuilder = ({
  reportType = '',
  paths = {},
  added = 0,
  fixed = 0,
  existing = 0,
  dismissed = 0,
  status = '',
}) => {
  let baseString = '';

  if (!paths.base && !paths.diffEndpoint) {
    if (added && !dismissed) {
      // added
      baseString = n__(
        'ciReport|%{reportType} %{status} detected %{newCount} vulnerability for the source branch only',
        'ciReport|%{reportType} %{status} detected %{newCount} vulnerabilities for the source branch only',
        added,
      );
    } else if (!added && dismissed) {
      // dismissed
      baseString = n__(
        'ciReport|%{reportType} %{status} detected %{dismissedCount} dismissed vulnerability for the source branch only',
        'ciReport|%{reportType} %{status} detected %{dismissedCount} dismissed vulnerabilities for the source branch only',
        dismissed,
      );
    } else if (added && dismissed) {
      // added & dismissed
      baseString = s__(
        'ciReport|%{reportType} %{status} detected %{newCount} new, and %{dismissedCount} dismissed vulnerabilities for the source branch only',
      );
    } else {
      // no vulnerabilities
      baseString = s__(
        'ciReport|%{reportType} %{status} detected no vulnerabilities for the source branch only',
      );
    }
  } else if (paths.head || paths.diffEndpoint) {
    if (added && !fixed && !dismissed) {
      // added
      baseString = n__(
        'ciReport|%{reportType} %{status} detected %{newCount} new vulnerability',
        'ciReport|%{reportType} %{status} detected %{newCount} new vulnerabilities',
        added,
      );
    } else if (!added && fixed && !dismissed) {
      // fixed
      baseString = n__(
        'ciReport|%{reportType} %{status} detected %{fixedCount} fixed vulnerability',
        'ciReport|%{reportType} %{status} detected %{fixedCount} fixed vulnerabilities',
        fixed,
      );
    } else if (!added && !fixed && dismissed) {
      // dismissed
      baseString = n__(
        'ciReport|%{reportType} %{status} detected %{dismissedCount} dismissed vulnerability',
        'ciReport|%{reportType} %{status} detected %{dismissedCount} dismissed vulnerabilities',
        dismissed,
      );
    } else if (added && fixed && !dismissed) {
      // added & fixed
      baseString = s__(
        'ciReport|%{reportType} %{status} detected %{newCount} new, and %{fixedCount} fixed vulnerabilities',
      );
    } else if (added && !fixed && dismissed) {
      // added & dismissed
      baseString = s__(
        'ciReport|%{reportType} %{status} detected %{newCount} new, and %{dismissedCount} dismissed vulnerabilities',
      );
    } else if (!added && fixed && dismissed) {
      // fixed & dismissed
      baseString = s__(
        'ciReport|%{reportType} %{status} detected %{fixedCount} fixed, and %{dismissedCount} dismissed vulnerabilities',
      );
    } else if (added && fixed && dismissed) {
      // added & fixed & dismissed
      baseString = s__(
        'ciReport|%{reportType} %{status} detected %{newCount} new, %{fixedCount} fixed, and %{dismissedCount} dismissed vulnerabilities',
      );
    } else if (existing) {
      baseString = s__('ciReport|%{reportType} %{status} detected no new vulnerabilities');
    } else {
      baseString = s__('ciReport|%{reportType} %{status} detected no vulnerabilities');
    }
  }

  if (!status) {
    baseString = baseString.replace('%{status}', '').replace('  ', ' ');
  }

  return sprintf(baseString, {
    status,
    reportType,
    newCount: added,
    fixedCount: fixed,
    dismissedCount: dismissed,
  });
};

export const statusIcon = (loading = false, failed = false, newIssues = 0, neutralIssues = 0) => {
  if (loading) {
    return 'loading';
  }

  if (failed || newIssues > 0 || neutralIssues > 0) {
    return 'warning';
  }

  return 'success';
};

/**
 * Counts issues. Simply returns the amount of existing and fixed Issues.
 * New Issues are divided into dismissed and added.
 *
 * @param newIssues
 * @param resolvedIssues
 * @param allIssues
 * @returns {{existing: number, added: number, dismissed: number, fixed: number}}
 */
export const countIssues = ({ newIssues = [], resolvedIssues = [], allIssues = [] } = {}) => {
  const dismissed = newIssues.reduce((sum, issue) => (issue.isDismissed ? sum + 1 : sum), 0);

  return {
    added: newIssues.length - dismissed,
    dismissed,
    existing: allIssues.length,
    fixed: resolvedIssues.length,
  };
};

/**
 * Generates a report message based on some of the report parameters and supplied messages.
 *
 * @param {Object} report The report to generate the text for
 * @param {String} reportType The report type. e.g. SAST
 * @param {String} errorMessage The message to show if there's an error in the report
 * @param {String} loadingMessage The message to show if the report is still loading
 * @returns {String}
 */
export const groupedReportText = (report, reportType, errorMessage, loadingMessage) => {
  const { paths } = report;

  if (report.hasError) {
    return errorMessage;
  }

  if (report.isLoading) {
    return loadingMessage;
  }

  return groupedTextBuilder({
    ...countIssues(report),
    reportType,
    paths,
  });
};

/**
 * Generates the added, fixed, and existing vulnerabilities from the API report.
 *
 * @param {Object} diff The original reports.
 * @param {Object} enrichData Feedback data to add to the reports.
 * @returns {Object}
 */
export const parseDiff = (diff, enrichData) => {
  const enrichVulnerability = vulnerability => ({
    ...enrichVulnerabilityWithFeedback(vulnerability, enrichData),
    category: vulnerability.report_type,
    title: vulnerability.message || vulnerability.name,
  });

  return {
    added: diff.added ? diff.added.map(enrichVulnerability) : [],
    fixed: diff.fixed ? diff.fixed.map(enrichVulnerability) : [],
    existing: diff.existing ? diff.existing.map(enrichVulnerability) : [],
  };
};
