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
      id: 'type',
      options: [
        {
          name: REPORT_TYPES.sast,
          id: 'sast',
          selected: true,
        },
      ],
    },
  ],
});
