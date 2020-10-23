import { CRITICAL, HIGH } from 'ee/security_dashboard/store/modules/vulnerabilities/constants';
import { __, n__, sprintf } from '~/locale';

/**
 * Returns the index of an issue in given list
 * @param {Array} issues
 * @param {Object} issue
 */
export const findIssueIndex = (issues, issue) =>
  issues.findIndex(el => el.project_fingerprint === issue.project_fingerprint);

/**
 * Takes an object of options and returns the object with an externalized string representing
 * the critical, high, and other severity vulnerabilities for a given report.
 *
 * The resulting string _may_ still contain sprintf-style placeholders. These
 * are left in place so they can be replaced with markup, via the
 * SecuritySummary component.
 * @param {{reportType: string, status: string, critical: number, high: number, other: number}} options
 * @returns {Object} the parameters with an externalized string
 */
export const groupedTextBuilder = ({
  reportType = '',
  status = '',
  critical = 0,
  high = 0,
  other = 0,
} = {}) => {
  const total = critical + high + other;
  const vulnMessage = n__('vulnerability', 'vulnerabilities', total);
  const otherMessage = n__('%d Other', '%d Others', other);

  let message;

  if (status) {
    message = __('%{reportType} %{status}');
  } else if (!total) {
    message = __('%{reportType} detected %{countStart}no%{countEnd} vulnerabilities.');
  } else {
    message = __(
      '%{reportType} detected %{countStart}%{total}%{countEnd} potential %{vulnMessage} %{criticalStart}%{critical} critical%{criticalEnd} %{highStart}%{high} high%{highEnd} and %{otherStart}%{otherMessage}%{otherEnd}',
    );
  }

  return {
    message: sprintf(message, {
      critical,
      high,
      otherMessage,
      reportType,
      status,
      total,
      vulnMessage,
    }).replace(/\s\s+/g, ' '),
    critical,
    high,
    other,
    status,
  };
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
 * Counts vulnerabilities.
 * Returns the amount of critical, high, and other vulnerabilities.
 *
 * @param {Array} vulnerabilities The raw vulnerabilities to parse
 * @returns {{critical: number, high: number, other: number}}
 */
export const countVulnerabilities = (vulnerabilities = []) => {
  const critical = vulnerabilities.filter(vuln => vuln.severity === CRITICAL).length;
  const high = vulnerabilities.filter(vuln => vuln.severity === HIGH).length;
  const other = vulnerabilities.length - critical - high;

  return {
    critical,
    high,
    other,
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
  if (report.hasError) {
    return { message: errorMessage };
  }

  if (report.isLoading) {
    return { message: loadingMessage };
  }

  return groupedTextBuilder({
    reportType,
    ...countVulnerabilities(report.newIssues),
  });
};
