import isPlainObject from 'lodash/isPlainObject';
import { s__ } from '~/locale';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import { ALL, BASE_FILTERS } from './store/modules/filters/constants';
import { REPORT_TYPES, SEVERITY_LEVELS } from './store/constants';
import { VULNERABILITY_STATES } from 'ee/vulnerabilities/constants';

const gl = 'GitLab';
let linkedFilters = [];

const createLinkedFilter = (linkId, id = []) => ({ linkId, id });
const createDisplayName = (name, vendor = gl) => `${name} - ${vendor}`;
const createLinkId = (id, vendor = gl) => `${id}_${vendor.toLowerCase()}`;

const createCustomFilters = (reportTypes, specificFilters) =>
  Object.keys(specificFilters).reduce(
    (all, vendor) => {
      if (vendor !== gl) {
        const newFilters = Object.values(specificFilters[vendor]).reduce(
          (acc, filter) => {
            const { reportType: id, externalIds } = filter;
            const name = reportTypes[id.toLowerCase()];
            const linkId = createLinkId(id, vendor);
            const customFilter = {
              displayName: createDisplayName(name, vendor),
              id,
              name,
              link: { id: 'scanner', linkId },
            };

            const linkedFilter = createLinkedFilter(linkId, externalIds);

            acc.customFilters.push(customFilter);
            acc.linkedFilters.push(linkedFilter);
            return acc;
          },
          { customFilters: [], linkedFilters: [] },
        );
        all.filters.push(...newFilters.customFilters);
        all.linkedFilters.push(...newFilters.linkedFilters);
      }
      return all;
    },
    { filters: [], linkedFilters: [] },
  );

const createGitlabFilters = (reportTypes, specificFilters) =>
  Object.entries(reportTypes).reduce(
    (acc, [id, name]) => {
      const linkId = createLinkId(id);
      const filter = {
        displayName: createDisplayName(name),
        id: id.toUpperCase(),
        name,
        link: { id: 'scanner', linkId },
      };

      const linkedFilter = createLinkedFilter(linkId);
      if (specificFilters[gl] && specificFilters[gl][id.toUpperCase()]) {
        linkedFilter.id = specificFilters[gl][id.toUpperCase()].externalIds;
      }

      acc.filters.push(filter);
      acc.linkedFilters.push(linkedFilter);
      return acc;
    },
    { filters: [], linkedFilters: [] },
  );

const parseReportTypes = (reportTypes, specificFilters) => {
  const customFilters = createCustomFilters(reportTypes, specificFilters);
  const gitlabFilters = createGitlabFilters(reportTypes, specificFilters);

  const filters = [...gitlabFilters.filters, ...customFilters.filters];
  linkedFilters = [...gitlabFilters.linkedFilters, ...customFilters.linkedFilters];

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
      name: s__('Reports|Scanner'),
      id: 'reportType',
      options: [BASE_FILTERS.report_type, ...parseReportTypes(REPORT_TYPES, specificFilters)],
      selection: new Set([ALL]),
    },
    {
      name: s__('Reports|Vendor'),
      id: 'scanner',
      hidden: true,
      options: linkedFilters,
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
