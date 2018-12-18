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
        {
          name: 'Critical',
          id: 'critical',
          selected: false,
        },
        {
          name: 'High',
          id: 'high',
          selected: false,
        },
        {
          name: 'Medium',
          id: 'medium',
          selected: false,
        },
        {
          name: 'Low',
          id: 'low',
          selected: false,
        },
        {
          name: 'Unknown',
          id: 'unknown',
          selected: false,
        },
        {
          name: 'Experimental',
          id: 'experimental',
          selected: false,
        },
        {
          name: 'Ignore',
          id: 'ignore',
          selected: false,
        },
        {
          name: 'Undefined',
          id: 'undefined',
          selected: false,
        },
      ],
    },
    {
      name: 'Report type',
      id: 'type',
      options: [
        {
          name: 'SAST',
          id: 'sast',
          selected: true,
        },
      ],
    },
  ],
});
