import { PRESET_TYPES, TIMELINE_CELL_MIN_WIDTH, MONTH } from 'ee/roadmap/constants';

import { mockMonthly, mockWeekly, mockQuarterly } from 'ee_jest/roadmap/mock_data';

import { createMockEpic } from 'ee_jest/roadmap/mock_helper';

const NOV_10_2020 = new Date(2020, MONTH.NOV, 10);
const JAN_1_2021 = new Date(2021, MONTH.JAN, 1);
const JUN_2_2021 = new Date(2021, MONTH.JUN, 2);
const DEC_31_2021 = new Date(2021, MONTH.DEC, 31);

export const presetTypeTestCases = [
  ['presetTypeQuarters', PRESET_TYPES.QUARTERS, mockQuarterly.timeframe],
  ['presetTypeMonths', PRESET_TYPES.MONTHS, mockMonthly.timeframe],
  ['presetTypeWeeks', PRESET_TYPES.WEEKS, mockWeekly.timeframe],
];

export const timeframeStringTestCases = [
  {
    when: 'both start and end dates are defined',
    propsData: {
      item: createMockEpic({ startDate: NOV_10_2020, endDate: JUN_2_2021 }),
    },
    expected: {
      timeframeString: 'Nov 10, 2020 – Jun 2, 2021',
    },
    returnCondition: '',
  },
  {
    when: 'no dates are defined',
    propsData: {
      item: createMockEpic({ startDate: undefined, endDate: undefined }),
    },
    expected: {
      timeframeString: 'No start and end date',
    },
    returnCondition: '',
  },
  {
    when: 'only start date is defined',
    propsData: {
      item: createMockEpic({ startDate: NOV_10_2020, endDate: undefined }),
    },
    expected: {
      timeframeString: 'Nov 10, 2020 – No end date',
    },
    returnCondition: '',
  },
  {
    when: 'only end date is defined',
    propsData: {
      item: createMockEpic({ startDate: undefined, endDate: JUN_2_2021 }),
    },
    expected: {
      timeframeString: 'No start date – Jun 2, 2021',
    },
    returnCondition: '',
  },
  {
    when: 'when both start and end dates are from same year',
    propsData: {
      item: createMockEpic({ startDate: JAN_1_2021, endDate: DEC_31_2021 }),
    },
    expected: {
      timeframeString: 'Jan 1 – Dec 31, 2021',
    },
    returnCondition: ' with hidden year for start date',
  },
];

const testCaseForTimeframeItem1 = {
  view: 'monthly',
  propsData: {
    presetType: PRESET_TYPES.MONTHS,
    item: createMockEpic({ startDate: NOV_10_2020 }),
    timeframe: mockMonthly.timeframe,
  },
  expected: {
    timeframeItemIndex: 1,
    timeframeItem: mockMonthly.timeframe[1],
  },
};

const testCaseForTimeframeItem2 = {
  view: 'weekly',
  propsData: {
    presetType: PRESET_TYPES.WEEKS,
    item: createMockEpic({ startDate: NOV_10_2020 }),
    timeframe: mockWeekly.timeframe,
  },
  expected: {
    timeframeItemIndex: 6,
    timeframeItem: mockWeekly.timeframe[6],
  },
};

const testCaseForTimeframeItem3 = {
  view: 'quarterly',
  propsData: {
    presetType: PRESET_TYPES.QUARTERS,
    item: createMockEpic({ startDate: NOV_10_2020 }),
    timeframe: mockQuarterly.timeframe,
  },
  expected: {
    timeframeItemIndex: 2,
    timeframeItem: mockQuarterly.timeframe[2],
  },
};

export const timeframeItemTestCases = [
  testCaseForTimeframeItem1,
  testCaseForTimeframeItem2,
  testCaseForTimeframeItem3,
];

const testCaseForTimelineBar1 = (() => {
  /*
    Test case commentary and visual illustration

    - Tests under monthly view
    - The epic starts on Dec 1, 2020 and ends on Dec 31, 2020.
      => timeframeItemIndex should be 2
      => the timeline bar should span the full width of a timeframe.

    Visualization:
                                          width = TIMELINE_CELL_MIN_WIDTH
                                       <- width ->
    timeframe = [[    0    ][    1    ][    2    ] ... [    7    ]]
                 <------ left -------->
                                            ^
                                      timeframeItemIndex == 2
  */

  const item = createMockEpic({
    startDate: new Date(2020, MONTH.DEC, 1),
    endDate: new Date(2020, MONTH.DEC, 31),
    timeframe: mockMonthly.timeframe,
  });
  const timeframeItemIndex = 2;

  return {
    when: 'an epic has a start date and an end date',
    propsData: {
      presetType: PRESET_TYPES.MONTHLY,
      item,
      timeframe: mockMonthly.timeframe,
    },
    expected: {
      width: `${TIMELINE_CELL_MIN_WIDTH}px`,
      left: `${TIMELINE_CELL_MIN_WIDTH * timeframeItemIndex}px`,
    },
  };
})();

const testCaseForTimelineBar2 = (() => {
  /*
    Test case commentary and visual illustration

    - Tests under weekly view
    - The epic starts on Oct 8, 2020 but has no end date.
      => timeframeItemIndex should be 1 since it falls on the week starting on Oct 5, 2020.
      => the timeline bar should span to the timeframe that comes before the very last timeframe
         (i.e., to the week starting on 2020-11-08).

    Visualization:

    [ 2020-09-27 ] means a timeframe that covers the week starting on 2020-09-27 + 1 = 2020-09-28.
                                       <-*-><--5 * TIMELINE_CELL_MIN_WIDTH-->
                                       <------- width of timeline bar ------>
    timeframe = [ 2020-09-27 ][ 2020-10-04 ][ 2020-10-11 ] ... [ 2020-11-08 ]
                <------------><-offset->
                <--------left---------->
                                     ^           
                                     ^ 
                          timeframeItemIndex == 1

  */
  const startDate = new Date(2020, MONTH.OCT, 8);
  const item = createMockEpic({ startDate, endDate: undefined, timeframe: mockWeekly.timeframe });

  // There are seven days in a week and each timeframe is TIMELINE_CELL_MIN_WIDTH px long.
  const widthOfEachDay = TIMELINE_CELL_MIN_WIDTH / 7;

  // The epic start date covers three days of the week starting on 2020-10-05.
  const widthInFirstFrame = widthOfEachDay * 3; // This is equivalent to <-*-> in the above picture.
  const restOfWidth = 5 * TIMELINE_CELL_MIN_WIDTH;
  const totalBarWidth = Math.round(widthInFirstFrame + restOfWidth);

  // offset calculation follows the formula in "getTimelineBarStartOffsetForWeeks"
  const offset = (startDate.getDay() + 1) * widthOfEachDay - widthOfEachDay / 2;
  const left = TIMELINE_CELL_MIN_WIDTH + offset;

  return {
    when: 'an epic has a start date but no end date',
    propsData: {
      presetType: PRESET_TYPES.WEEKS,
      item,
      timeframe: mockWeekly.timeframe,
    },
    expected: {
      width: `${totalBarWidth}px`,
      left: `${left}px`,
    },
  };
})();

const testCaseForTimelineBar3 = (() => {
  /*
      Test case commentary and visual illustration

      - Tests under quarterly view
      - The epic has no start date but ends on MAR 31, 2021 or 2021 Q1
        => startDate should be set to the first timeframe (2020 Q2).
        => the timeline bar should span from the beginning of the timeframe
            to MAR 31, 2021 or 2021 Q1 (total of 4 quarters)

      Visualization:
                    <------- width ------->
      timeframe = [[ Q2 ][ Q3 ][ Q4 ][ Q1 ][ Q2 ][ Q3 ][ Q4 ]]
                   |     2020       ||        2021          |
                   ^
                   left offset should be 0.
    */
  const item = createMockEpic({
    startDate: undefined,
    endDate: new Date(2021, MONTH.MAR, 31),
    timeframe: mockQuarterly.timeframe,
    useQuarterlyTimeframe: true,
  });

  return {
    when: "an epic doesn't have a start date but has an end date",
    propsData: {
      presetType: PRESET_TYPES.QUARTERS,
      item,
      timeframe: mockQuarterly.timeframe,
    },
    expected: {
      width: `${TIMELINE_CELL_MIN_WIDTH * 4}px`,
      left: '0px',
    },
  };
})();

export const timelineBarTestCases = [
  testCaseForTimelineBar1,
  testCaseForTimelineBar2,
  testCaseForTimelineBar3,
];
