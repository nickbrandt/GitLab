import {
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
} from 'ee/feature_flags/constants';

export const featureFlag = {
  id: 1,
  active: true,
  created_at: '2018-12-12T22:07:31.401Z',
  updated_at: '2018-12-12T22:07:31.401Z',
  name: 'test flag',
  description: 'flag for tests',
  destroy_path: 'feature_flags/1',
  update_path: 'feature_flags/1',
  edit_path: 'feature_flags/1/edit',
  scopes: [
    {
      id: 1,
      active: true,
      environment_scope: '*',
      can_update: true,
      protected: false,
      created_at: '2019-01-14T06:41:40.987Z',
      updated_at: '2019-01-14T06:41:40.987Z',
      strategies: [
        {
          name: ROLLOUT_STRATEGY_ALL_USERS,
          parameters: {},
        },
      ],
    },
    {
      id: 2,
      active: false,
      environment_scope: 'production',
      can_update: true,
      protected: false,
      created_at: '2019-01-14T06:41:40.987Z',
      updated_at: '2019-01-14T06:41:40.987Z',
      strategies: [
        {
          name: ROLLOUT_STRATEGY_ALL_USERS,
          parameters: {},
        },
      ],
    },
    {
      id: 3,
      active: false,
      environment_scope: 'review/*',
      can_update: true,
      protected: false,
      created_at: '2019-01-14T06:41:40.987Z',
      updated_at: '2019-01-14T06:41:40.987Z',
      strategies: [
        {
          name: ROLLOUT_STRATEGY_ALL_USERS,
          parameters: {},
        },
      ],
    },
    {
      id: 4,
      active: true,
      environment_scope: 'development',
      can_update: true,
      protected: false,
      created_at: '2019-01-14T06:41:40.987Z',
      updated_at: '2019-01-14T06:41:40.987Z',
      strategies: [
        {
          name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
          parameters: {
            percentage: '86',
          },
        },
      ],
    },
  ],
};

export const getRequestData = {
  feature_flags: [featureFlag],
  count: {
    all: 1,
    disabled: 1,
    enabled: 0,
  },
};

export const rotateData = { token: 'oP6sCNRqtRHmpy1gw2-F' };
