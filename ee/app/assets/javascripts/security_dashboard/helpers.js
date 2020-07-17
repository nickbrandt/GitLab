import isPlainObject from 'lodash/isPlainObject';
import { s__ } from '~/locale';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import { ALL, BASE_FILTERS } from './store/modules/filters/constants';
import { REPORT_TYPES, SEVERITY_LEVELS } from './store/constants';
import { VULNERABILITY_STATES } from 'ee/vulnerabilities/constants';

const parseReportTypes = (obj, specificFilters) => {
  const filters = [];
  Object.keys(specificFilters).forEach(vendor => {
    if (vendor !== 'GitLab') {
      const customFilters = Object.values(specificFilters[vendor]).map(filter => {
        const { reportType: id, externalIds } = filter;
        const name = obj[id.toLowerCase()];
        return {
          id,
          name,
          displayName: `${name} - ${vendor}`,
          externalIds,
        };
      });
      filters.push(...customFilters);
    }
  });

  const gitlabFilters = Object.entries(obj).map(([id, name]) => {
    const filter = {
      displayName: `${name} - GitLab`,
      externalIds: [],
      id: id.toUpperCase(),
      name,
    };

    if (specificFilters['GitLab'] && specificFilters['GitLab'][id.toUpperCase()]) {
      filter.externalIds = specificFilters['GitLab'][id.toUpperCase()].externalIds;
    }

    return filter;
  });
  filters.push(...gitlabFilters);

  return filters;
};

const parseOptions = obj =>
  Object.entries(obj).map(([id, name]) => ({ id: id.toUpperCase(), name }));

export const mapProjects = projects =>
  projects.map(p => ({ id: p.id.split('/').pop(), name: p.name }));

export const initFirstClassVulnerabilityFilters = (projects, specificFilters) => {
  const filters = [
    {
      name: s__('SecurityReports|Status'),
      ids: { state: 'id' },
      options: [
        { id: ALL, name: s__('VulnerabilityStatusTypes|All') },
        ...parseOptions(VULNERABILITY_STATES),
      ],
      selection: new Set([ALL]),
      selectionObj: { ALL },
    },
    {
      name: s__('SecurityReports|Severity'),
      ids: { severity: 'id' },
      options: [BASE_FILTERS.severity, ...parseOptions(SEVERITY_LEVELS)],
      selection: new Set([ALL]),
      selectionObj: { ALL },
    },
    {
      name: s__('Reports|Scanner'),
      ids: { reportType: 'id', scanner: 'externalIds' },
      options: [BASE_FILTERS.report_type, ...parseReportTypes(REPORT_TYPES, specificFilters)],
      selection: new Set([ALL]),
      selectionObj: { ALL },
    },
  ];

  if (Array.isArray(projects)) {
    filters.push({
      name: s__('SecurityReports|Project'),
      ids: { projectId: 'id' },
      options: [BASE_FILTERS.project_id, ...mapProjects(projects)],
      selection: new Set([ALL]),
      selectionObj: { ALL },
    });
  }

  return filters;
};

/**
 * Provided a security reports summary from the GraphQL API, this returns an array of arrays
 * representing a properly formatted report ready to be displayed in the UI. Each sub-array consists
 * of the user-friend report's name, and the summary's payload. Note that summary entries are
 * considered empty and are filtered out of the return if the payload is `null` or don't include
 * a vulnerabilitiesCount property. Report types whose name can't be matched to a user-friendly
 * name are filtered out as well.
 *
 * Take the following summary for example:
 * {
 *   containerScanning: { vulnerabilitiesCount: 123 },
 *   invalidReportType: { vulnerabilitiesCount: 123 },
 *   dast: null,
 * }
 *
 * The formatted summary would look like this:
 * [
 *   ['containerScanning', { vulnerabilitiesCount: 123 }]
 * ]
 *
 * Note that `invalidReportType` was filtered out as it can't be matched with a user-friendly name,
 * and the DAST report was omitted because it's empty (`null`).
 *
 * @param {Object} rawSummary
 * @returns {Array}
 */
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
