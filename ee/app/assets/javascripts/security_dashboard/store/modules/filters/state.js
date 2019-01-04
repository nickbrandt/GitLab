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
          selected: true,
        },
        ...Object.entries(SEVERITIES).map(severity => {
          const [id, name] = severity;
          return { id, name };
        }),
      ],
    },
    {
      name: 'Report type',
      id: 'report_type',
      options: [
        {
          name: 'All',
          id: 'all',
          selected: true,
        },
        ...Object.entries(REPORT_TYPES).map(type => {
          const [id, name] = type;
          return { id, name };
        }),
      ],
    },
  ],
});
