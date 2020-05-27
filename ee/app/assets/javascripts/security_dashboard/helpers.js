import { s__ } from '~/locale';
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
      name: s__('Reports|Scanner'),
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

export default () => ({});
