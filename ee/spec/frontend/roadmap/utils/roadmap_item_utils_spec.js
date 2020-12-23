import * as roadmapItemUtils from 'ee/roadmap/utils/roadmap_item_utils';

import { PRESET_TYPES } from 'ee/roadmap/constants';
import { dateFromString, parsePikadayDate } from '~/lib/utils/datetime_utility';

import { rawEpics, mockGroupMilestonesQueryResponse } from '../mock_data';

const mockQuarterlyTimeframe = [
  {
    range: [
      dateFromString('Jan 1 2020'),
      dateFromString('Feb 1 2020'),
      dateFromString('Mar 1 2020'),
    ],
  },
  {
    range: [
      dateFromString('Apr 1 2020'),
      dateFromString('May 1 2020'),
      dateFromString('Jun 1 2020'),
    ],
  },
];

const mockMonthlyTimeframe = [
  dateFromString('Jan 1 2020'),
  dateFromString('Feb 1 2020'),
  dateFromString('Mar 1 2020'),
];

const mockWeeklyTimeframe = [
  dateFromString('Dec 6 2020'),
  dateFromString('Dec 13 2020'),
  dateFromString('Dec 20 2020'),
];

describe('processRoadmapItemDates', () => {
  const timeframeStartDate = new Date(2017, 0, 1);
  const timeframeEndDate = new Date(2017, 11, 31);

  it('should set `startDateOutOfRange`/`endDateOutOfRange` as true and `startDate` and `endDate` to dates of timeframe range when epic dates are outside timeframe range', () => {
    const mockEpic = {
      originalStartDate: new Date(2016, 11, 15),
      originalEndDate: new Date(2018, 0, 1),
    };

    const updatedEpic = roadmapItemUtils.processRoadmapItemDates(
      mockEpic,
      timeframeStartDate,
      timeframeEndDate,
    );

    expect(updatedEpic.startDateOutOfRange).toBe(true);
    expect(updatedEpic.endDateOutOfRange).toBe(true);
    expect(updatedEpic.startDate.getTime()).toBe(timeframeStartDate.getTime());
    expect(updatedEpic.endDate.getTime()).toBe(timeframeEndDate.getTime());
  });

  it('should set `startDateOutOfRange`/`endDateOutOfRange` as false and `startDate` and `endDate` to actual epic dates when they are within timeframe range', () => {
    const mockEpic = {
      originalStartDate: new Date(2017, 2, 10),
      originalEndDate: new Date(2017, 6, 22),
    };

    const updatedEpic = roadmapItemUtils.processRoadmapItemDates(
      mockEpic,
      timeframeStartDate,
      timeframeEndDate,
    );

    expect(updatedEpic.startDateOutOfRange).toBe(false);
    expect(updatedEpic.endDateOutOfRange).toBe(false);
    expect(updatedEpic.startDate.getTime()).toBe(mockEpic.originalStartDate.getTime());
    expect(updatedEpic.endDate.getTime()).toBe(mockEpic.originalEndDate.getTime());
  });

  it('should set `startDate` and `endDate` to timeframe start and end dates when epic dates are undefined', () => {
    const mockEpic = {
      startDateUndefined: true,
      endDateUndefined: true,
    };

    const updatedEpic = roadmapItemUtils.processRoadmapItemDates(
      mockEpic,
      timeframeStartDate,
      timeframeEndDate,
    );

    expect(updatedEpic.startDate.getTime()).toBe(timeframeStartDate.getTime());
    expect(updatedEpic.endDate.getTime()).toBe(timeframeEndDate.getTime());
  });
});

describe('formatRoadmapItemDetails', () => {
  const timeframeStartDate = new Date(2017, 0, 1);
  const timeframeEndDate = new Date(2017, 11, 31);
  const rawEpic = rawEpics[0];

  it('Should return formatted Epic object from raw Epic object', () => {
    const epic = roadmapItemUtils.formatRoadmapItemDetails(
      rawEpic,
      timeframeStartDate,
      timeframeEndDate,
    );

    expect(epic.id).toBe(rawEpic.id);
    expect(epic.name).toBe(rawEpic.name);
    expect(epic.groupId).toBe(rawEpic.group_id);
    expect(epic.groupName).toBe(rawEpic.group_name);
  });

  it('should return formatted Epic object with `startDate`/`endDate` and `originalStartDate`/originalEndDate` initialized when dates are present', () => {
    const mockRawEpic = {
      start_date: '2017-2-15',
      end_date: '2017-7-22',
    };

    const epic = roadmapItemUtils.formatRoadmapItemDetails(
      mockRawEpic,
      timeframeStartDate,
      timeframeEndDate,
    );

    const startDate = parsePikadayDate(mockRawEpic.start_date);
    const endDate = parsePikadayDate(mockRawEpic.end_date);

    expect(epic.startDate.getTime()).toBe(startDate.getTime());
    expect(epic.originalStartDate.getTime()).toBe(startDate.getTime());
    expect(epic.endDate.getTime()).toBe(endDate.getTime());
    expect(epic.originalEndDate.getTime()).toBe(endDate.getTime());
  });

  it('should return formatted Epic object with `startDateUndefined`/startDateUndefined` set to true when dates are null/undefined', () => {
    const epic = roadmapItemUtils.formatRoadmapItemDetails(
      {},
      timeframeStartDate,
      timeframeEndDate,
    );

    expect(epic.originalStartDate).toBeUndefined();
    expect(epic.originalEndDate).toBeUndefined();
    expect(epic.startDateUndefined).toBe(true);
    expect(epic.endDateUndefined).toBe(true);
  });
});

describe('extractGroupMilestones', () => {
  it('returns array of epics with `edges->nodes` nesting removed', () => {
    const { edges } = mockGroupMilestonesQueryResponse.data.group.milestones;
    const extractedMilestones = roadmapItemUtils.extractGroupMilestones(edges);

    expect(extractedMilestones).toHaveLength(edges.length);
    expect(extractedMilestones[0]).toEqual(
      expect.objectContaining({
        ...edges[0].node,
      }),
    );
  });
});

describe('lastTimeframeIndex', () => {
  it('should return last index of the timeframe array', () => {
    const timeframe = [1, 2, 3, 4];

    expect(roadmapItemUtils.lastTimeframeIndex(timeframe)).toBe(3);
  });
});

describe('timeframeStartDate', () => {
  it.each`
    presetType               | firstItem                       | timeframe
    ${PRESET_TYPES.QUARTERS} | ${dateFromString('Jan 1 2020')} | ${mockQuarterlyTimeframe}
    ${PRESET_TYPES.MONTHS}   | ${dateFromString('Jan 1 2020')} | ${mockMonthlyTimeframe}
    ${PRESET_TYPES.WEEKS}    | ${dateFromString('Dec 6 2020')} | ${mockWeeklyTimeframe}
  `(
    `should return first item of the timeframe range array when preset type is $presetType`,
    ({ presetType, firstItem, timeframe }) => {
      expect(roadmapItemUtils.timeframeStartDate(presetType, timeframe)).toEqual(firstItem);
    },
  );
});

describe('timeframeEndDate', () => {
  /*
    Note that for a weekly timeframe, lastItem should point to the ending date of a week.
    For example, if in mockWeeklyTimeframe, 'Dec 20 2020' is the last item.
    However, the ending date for that week is 'Dec 27 2020'.
   */
  it.each`
    presetType               | lastItem                         | timeframe
    ${PRESET_TYPES.QUARTERS} | ${dateFromString('Jun 1 2020')}  | ${mockQuarterlyTimeframe}
    ${PRESET_TYPES.MONTHS}   | ${dateFromString('Mar 1 2020')}  | ${mockMonthlyTimeframe}
    ${PRESET_TYPES.WEEKS}    | ${dateFromString('Dec 27 2020')} | ${mockWeeklyTimeframe}
  `(
    `should return last item of the timeframe range array when preset type is $presetType`,
    ({ presetType, lastItem, timeframe }) => {
      expect(roadmapItemUtils.timeframeEndDate(presetType, timeframe)).toEqual(lastItem);
    },
  );
});
