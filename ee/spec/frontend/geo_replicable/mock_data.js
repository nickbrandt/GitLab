import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export const MOCK_GEO_REPLICATION_SVG_PATH = 'illustrations/empty-state/geo-replication-empty.svg';

export const MOCK_GEO_TROUBLESHOOTING_LINK =
  'https://docs.gitlab.com/ee/administration/geo/replication/troubleshooting.html';

export const MOCK_REPLICABLE_TYPE = 'designs';

export const MOCK_BASIC_FETCH_RESPONSE = {
  data: [
    {
      id: 1,
      project_id: 1,
      name: 'zack test 1',
      state: 'pending',
      last_synced_at: null,
    },
    {
      id: 2,
      project_id: 2,
      name: 'zack test 2',
      state: 'synced',
      last_synced_at: null,
    },
  ],
  headers: {
    'x-per-page': 20,
    'x-total': 100,
  },
};

export const MOCK_BASIC_FETCH_DATA_MAP = {
  data: convertObjectPropsToCamelCase(MOCK_BASIC_FETCH_RESPONSE.data, { deep: true }),
  perPage: MOCK_BASIC_FETCH_RESPONSE.headers['x-per-page'],
  total: MOCK_BASIC_FETCH_RESPONSE.headers['x-total'],
};

export const MOCK_BASIC_POST_RESPONSE = {
  status: 'ok',
};
