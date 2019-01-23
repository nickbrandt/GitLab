import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

import { TEST_HOST } from 'spec/test_constants';

const metaFixture = getJSONFixture('epic/mock_meta.json');
const meta = JSON.parse(metaFixture.meta);
const initial = JSON.parse(metaFixture.initial);

export const mockEpicMeta = convertObjectPropsToCamelCase(meta, {
  deep: true,
});

export const mockEpicData = convertObjectPropsToCamelCase(
  Object.assign({}, getJSONFixture('epic/mock_data.json'), initial, {
    endpoint: TEST_HOST,
    sidebarCollapsed: false,
  }),
  { deep: true },
);
