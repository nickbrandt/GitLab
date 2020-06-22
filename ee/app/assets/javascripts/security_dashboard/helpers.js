import isPlainObject from 'lodash/isPlainObject';
import { s__ } from '~/locale';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import { ALL, BASE_FILTERS } from 'ee/security_dashboard/store/modules/filters/constants';
import { REPORT_TYPES, SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';
import { VULNERABILITY_STATES } from 'ee/vulnerabilities/constants';

const parseOptions = obj =>
  Object.entries(obj).map(([id, name]) => ({ id: id.toUpperCase(), name }));

export const mapProjects = projects =>
  projects.map(p => ({ id: p.id.split('/').pop(), name: p.name }));

export const initFirstClassVulnerabilityFilters = projects => {
  const filters = [
    {
      name: s__('SecurityReports|Status'),
      id: 'state',
      options: [
        { id: ALL, name: s__('VulnerabilityStatusTypes|All') },
        ...parseOptions(VULNERABILITY_STATES),
      ],
      selection: new Set([ALL]),
    },
    {
      name: s__('SecurityReports|Severity'),
      id: 'severity',
      options: [BASE_FILTERS.severity, ...parseOptions(SEVERITY_LEVELS)],
      selection: new Set([ALL]),
    },
    {
      name: s__('SecurityReports|Report type'),
      id: 'reportType',
      options: [BASE_FILTERS.report_type, ...parseOptions(REPORT_TYPES)],
      selection: new Set([ALL]),
    },
  ];

  if (Array.isArray(projects)) {
    filters.push({
      name: s__('SecurityReports|Project'),
      id: 'projectId',
      options: [BASE_FILTERS.project_id, ...mapProjects(projects)],
      selection: new Set([ALL]),
    });
  }

  return filters;
};

export const getFormattedSummary = (rawSummary = {}) => {
  if (!isPlainObject(rawSummary)) {
    return [];
  }
  // Convert keys to snake case so they can be matched against REPORT_TYPES keys for translation
  const snakeCasedSummary = convertObjectPropsToSnakeCase(rawSummary);
  // Convert object to an array of entries to make it easier to loop through
  const summaryEntries = Object.entries(snakeCasedSummary);
  // Filter out empty entries as we don't want to display those in the summary
  const withoutEmptyEntries = summaryEntries.filter(
    ([, scanSummary]) => scanSummary?.vulnerabilitiesCount !== undefined,
  );
  // Replace keys with translations found in REPORT_TYPES if available
  const formattedEntries = withoutEmptyEntries.map(([scanType, scanSummary]) => {
    const name = REPORT_TYPES[scanType];
    return name ? [name, scanSummary] : null;
  });
  // Filter out keys that could not be matched with any translation and are thus considered invalid
  return formattedEntries.filter(entry => entry !== null);
};

export default () => ({});
