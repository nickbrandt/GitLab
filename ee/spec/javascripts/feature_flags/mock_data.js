export const featureFlagsList = [
  {
    id: 1,
    active: true,
    created_at: '2018-12-12T22:07:31.401Z',
    updated_at: '2018-12-12T22:07:31.401Z',
    name: 'test flag',
    description: 'flag for tests',
    destroy_path: 'feature_flags/1',
    edit_path: 'feature_flags/1/edit',
  },
];

export const featureFlag = {
  id: 1,
  active: true,
  created_at: '2018-12-12T22:07:31.401Z',
  updated_at: '2018-12-12T22:07:31.401Z',
  name: 'test flag',
  description: 'flag for tests',
  destroy_path: 'feature_flags/1',
  edit_path: 'feature_flags/1/edit',
  scopes: [
    {
      id: 1,
      active: true,
      environment_scope: '*',
      created_at: '2019-01-14T06:41:40.987Z',
      updated_at: '2019-01-14T06:41:40.987Z',
    },
    {
      id: 2,
      active: false,
      environment_scope: 'production',
      created_at: '2019-01-14T06:41:40.987Z',
      updated_at: '2019-01-14T06:41:40.987Z',
    },
  ],
};

export const getRequestData = {
  feature_flags: [
    {
      id: 3,
      active: true,
      created_at: '2019-01-14T06:41:40.987Z',
      updated_at: '2019-01-14T06:41:40.987Z',
      name: 'ci_live_trace',
      description: 'For the new live trace architecture',
      edit_path: '/root/per-environment-feature-flags/-/feature_flags/3/edit',
      destroy_path: '/root/per-environment-feature-flags/-/feature_flags/3',
      scopes: [
        {
          id: 1,
          active: true,
          environment_scope: '*',
          created_at: '2019-01-14T06:41:40.987Z',
          updated_at: '2019-01-14T06:41:40.987Z',
        },
        {
          id: 2,
          active: false,
          environment_scope: 'production',
          created_at: '2019-01-14T06:41:40.987Z',
          updated_at: '2019-01-14T06:41:40.987Z',
        },
        {
          id: 3,
          active: false,
          environment_scope: 'review/*',
          created_at: '2019-01-14T06:41:40.987Z',
          updated_at: '2019-01-14T06:41:40.987Z',
        },
      ],
    },
  ],
  count: {
    all: 1,
    disabled: 1,
    enabled: 0,
  },
};
