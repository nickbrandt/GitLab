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

export const mockDatePickerProps = {
  blockClass: 'epic-date',
  sidebarCollapsed: false,
  showToggleSidebar: false,
  dateSaveInProgress: false,
  canUpdate: true,
  label: 'Date',
  datePickerLabel: 'Fixed date',
  selectedDate: null,
  selectedDateIsFixed: true,
  dateFromMilestones: null,
  dateFixed: null,
  dateFromMilestonesTooltip: 'Select an issue with milestone to set date',
  isDateInvalid: false,
  dateInvalidTooltip: 'Selected date is invalid',
};

export const mockLabels = [
  {
    id: 26,
    title: 'Foo Label',
    description: 'Foobar',
    color: '#BADA55',
    text_color: '#FFFFFF',
  },
];

export const mockParentEpic = {
  id: 1,
  title: 'Sample Parent Epic',
  url: '/groups/gitlab-org/-/epics/6',
};
