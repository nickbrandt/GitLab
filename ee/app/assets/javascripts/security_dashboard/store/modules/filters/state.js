import { SEVERITY_LEVELS, REPORT_TYPES, BASE_FILTERS } from './constants';

const optionsObjectToArray = obj => Object.entries(obj).map(([id, name]) => ({ id, name }));

export default () => ({
  filters: [
    {
      name: 'Severity',
      id: 'severity',
      options: [BASE_FILTERS.severity, ...optionsObjectToArray(SEVERITY_LEVELS)],
      selection: new Set(['all']),
    },
    {
      name: 'Report type',
      id: 'report_type',
      options: [BASE_FILTERS.report_type, ...optionsObjectToArray(REPORT_TYPES)],
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
