import { REPORT_TYPES } from 'ee/security_dashboard/store/constants';

/**
 * Takes the report type, that is not human-readable and converts it to be human-readable
 * @param {string} reportType that is not human-readable
 * @returns {string} the conversion from REPORT_TYPES or a lowercase version without '_' in it to
 *                   be paired with the CSS class `text-capitalize`
 */
const convertReportType = reportType => {
  if (!reportType) return '';
  const lowerCaseType = reportType.toLowerCase();
  return REPORT_TYPES[lowerCaseType] || lowerCaseType.split('_').join(' ');
};

export default convertReportType;
