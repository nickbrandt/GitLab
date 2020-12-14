import { formatRoadmapItemDetails } from 'ee/roadmap/utils/roadmap_item_utils';
import { DAYS_IN_WEEK } from 'ee/roadmap/constants';
import { mockEpicBase, mockMonthly } from 'ee_jest/roadmap/mock_data';
import { pikadayToString } from '~/lib/utils/datetime_utility';

/*
  Words of caution on the validity of the mock epics and milestones used in roadmap specs:

  We fetch a list of raw roadmap items from the backend (please refer to vuex actions):
    list = [ rawRoadmapItem0, rawRoadmapItem1, ... ]
    - note that "rawRoadmapItem"'s may or may not have startDate and dueDate.

  Then each item from fetchedRawData is fed into this function (from roadmap_item_utils):
    formatRoadmapItemDetails(rawRoadmapItem, timeframeStartDate, timeframeEndDate)
  
  Depending on the item's start/dueDate and the given timeframe, the following properties are modified or added:
    startDate, endDate, startDateUndefined, originalStartDate, endDateOutOfRange, originalEndDate.

  The takeaways are:
  1) The validity of the mock data we write is tightly coupled to what timeframe we choose to use!
  2) Some field may or may not exist:
      "startDateUndefined" is not explicitly "false" when startDate doesn't exist.
      The field itself won't be defined.
  
  The recommendations are:

  1. Use mockEpicBase and compose a complete mock item on a case-by-case basis like this:
  mockItem = { ...mockEpicBase, startDate: new Date(2020, 8, 1), endDate: new Date(2021, 0, 10) }

  or

  2. Use a helper like "createMockEpic" here to generate a valid mock.
*/

export const createMockEpic = ({
  startDate = undefined,
  endDate = undefined,
  timeframe = mockMonthly.timeframe,
  // Elements that go into a quarterly timeframe have a special format,
  // thus we need to be aware of it.
  useQuarterlyTimeframe = false,
  mockBase = mockEpicBase,
}) => {
  const mockItem = { ...mockBase };
  let timeframeStartDate;
  let lastTimeframe;

  if (useQuarterlyTimeframe) {
    // eslint-disable-next-line prefer-destructuring
    timeframeStartDate = timeframe[0].range[0];
    // eslint-disable-next-line prefer-destructuring
    lastTimeframe = timeframe[timeframe.length - 1].range[2];
  } else {
    [timeframeStartDate] = timeframe;
    lastTimeframe = timeframe[timeframe.length - 1];
  }

  const timeframeEndDate = new Date(lastTimeframe);
  timeframeEndDate.setDate(timeframeEndDate.getDate() + DAYS_IN_WEEK);

  // formatRoadmapItemDetails only accept Pick-a-day strings
  if (startDate) {
    mockItem.startDate = pikadayToString(startDate);
  }

  if (endDate) {
    mockItem.dueDate = pikadayToString(endDate);
  }

  return formatRoadmapItemDetails(mockItem, timeframeStartDate, timeframeEndDate);
};
