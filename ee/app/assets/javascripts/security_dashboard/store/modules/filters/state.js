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
          id: 7,
          selected: false,
        },
        {
          name: 'High',
          id: 6,
          selected: false,
        },
        {
          name: 'Medium',
          id: 5,
          selected: false,
        },
        {
          name: 'Low',
          id: 4,
          selected: false,
        },
        {
          name: 'Unknown',
          id: 2,
          selected: false,
        },
        {
          name: 'Experimental',
          id: 3,
          selected: false,
        },
        {
          name: 'Ignore',
          id: 1,
          selected: false,
        },
        {
          name: 'Undefined',
          id: 0,
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
