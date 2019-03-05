import { SEVERITY_LEVELS, REPORT_TYPES, BASE_FILTERS } from './constants';

const mapToArray = map => Object.entries(map).map(([id, name]) => ({ id, name }));

export default () => ({
  filters: [
    {
      name: 'Severity',
      id: 'severity',
      options: [BASE_FILTERS.severity, ...mapToArray(SEVERITY_LEVELS)],
      selection: new Set(['all']),
    },
    {
      name: 'Report type',
      id: 'report_type',
      options: [BASE_FILTERS.report_type, ...mapToArray(REPORT_TYPES)],
      selection: new Set(['all']),
    },
    {
      name: 'Project',
      id: 'project_id',
      options: [BASE_FILTERS.project_id],
      selection: new Set(['all']),
    },
  ],
});
