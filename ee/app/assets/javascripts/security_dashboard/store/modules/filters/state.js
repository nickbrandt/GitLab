import { SEVERITIES, REPORT_TYPES } from './constants';

export default () => ({
  filters: [
    {
      name: 'Severity',
      id: 'severity',
      options: [
        {
          name: 'All',
          id: 'all',
        },
        ...Object.entries(SEVERITIES).map(severity => {
          const [id, name] = severity;
          return { id, name };
        }),
      ],
      selection: new Set(['all']),
    },
    {
      name: 'Report type',
      id: 'report_type',
      options: [
        {
          name: 'All',
          id: 'all',
        },
        ...Object.entries(REPORT_TYPES).map(type => {
          const [id, name] = type;
          return { id, name };
        }),
      ],
      selection: new Set(['all']),
    },
    {
      name: 'Project',
      id: 'project_id',
      options: [
        {
          name: 'All',
          id: 'all',
        },
      ],
      selection: new Set(['all']),
    },
  ],
});
