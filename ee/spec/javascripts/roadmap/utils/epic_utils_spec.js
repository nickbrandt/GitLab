import * as epicUtils from 'ee/roadmap/utils/epic_utils';

import { parsePikadayDate } from '~/lib/utils/datetime_utility';

import { rawEpics, mockGroupEpicsQueryResponse } from '../mock_data';

describe('processEpicDates', () => {
  const timeframeStartDate = new Date(2017, 0, 1);
  const timeframeEndDate = new Date(2017, 11, 31);

  it('Should set `startDateOutOfRange`/`endDateOutOfRange` as true and `startDate` and `endDate` to dates of timeframe range when epic dates are outside timeframe range', () => {
    const mockEpic = {
      originalStartDate: new Date(2016, 11, 15),
      originalEndDate: new Date(2018, 0, 1),
    };

    const updatedEpic = epicUtils.processEpicDates(mockEpic, timeframeStartDate, timeframeEndDate);

    expect(updatedEpic.startDateOutOfRange).toBe(true);
    expect(updatedEpic.endDateOutOfRange).toBe(true);
    expect(updatedEpic.startDate.getTime()).toBe(timeframeStartDate.getTime());
    expect(updatedEpic.endDate.getTime()).toBe(timeframeEndDate.getTime());
  });

  it('Should set `startDateOutOfRange`/`endDateOutOfRange` as false and `startDate` and `endDate` to actual epic dates when they are within timeframe range', () => {
    const mockEpic = {
      originalStartDate: new Date(2017, 2, 10),
      originalEndDate: new Date(2017, 6, 22),
    };

    const updatedEpic = epicUtils.processEpicDates(mockEpic, timeframeStartDate, timeframeEndDate);

    expect(updatedEpic.startDateOutOfRange).toBe(false);
    expect(updatedEpic.endDateOutOfRange).toBe(false);
    expect(updatedEpic.startDate.getTime()).toBe(mockEpic.originalStartDate.getTime());
    expect(updatedEpic.endDate.getTime()).toBe(mockEpic.originalEndDate.getTime());
  });

  it('Should set `startDate` and `endDate` to timeframe start and end dates when epic dates are undefined', () => {
    const mockEpic = {
      startDateUndefined: true,
      endDateUndefined: true,
    };

    const updatedEpic = epicUtils.processEpicDates(mockEpic, timeframeStartDate, timeframeEndDate);

    expect(updatedEpic.startDate.getTime()).toBe(timeframeStartDate.getTime());
    expect(updatedEpic.endDate.getTime()).toBe(timeframeEndDate.getTime());
  });
});

describe('formatEpicDetails', () => {
  const timeframeStartDate = new Date(2017, 0, 1);
  const timeframeEndDate = new Date(2017, 11, 31);
  const rawEpic = rawEpics[0];

  it('Should return formatted Epic object from raw Epic object', () => {
    const epic = epicUtils.formatEpicDetails(rawEpic, timeframeStartDate, timeframeEndDate);

    expect(epic.id).toBe(rawEpic.id);
    expect(epic.name).toBe(rawEpic.name);
    expect(epic.groupId).toBe(rawEpic.group_id);
    expect(epic.groupName).toBe(rawEpic.group_name);
  });

  it('Should return formatted Epic object with `startDate`/`endDate` and `originalStartDate`/originalEndDate` initialized when dates are present', () => {
    const mockRawEpic = {
      start_date: '2017-2-15',
      end_date: '2017-7-22',
    };

    const epic = epicUtils.formatEpicDetails(mockRawEpic, timeframeStartDate, timeframeEndDate);

    const startDate = parsePikadayDate(mockRawEpic.start_date);
    const endDate = parsePikadayDate(mockRawEpic.end_date);

    expect(epic.startDate.getTime()).toBe(startDate.getTime());
    expect(epic.originalStartDate.getTime()).toBe(startDate.getTime());
    expect(epic.endDate.getTime()).toBe(endDate.getTime());
    expect(epic.originalEndDate.getTime()).toBe(endDate.getTime());
  });

  it('Should return formatted Epic object with `startDateUndefined`/startDateUndefined` set to true when dates are null/undefined', () => {
    const epic = epicUtils.formatEpicDetails({}, timeframeStartDate, timeframeEndDate);

    expect(epic.originalStartDate).toBeUndefined();
    expect(epic.originalEndDate).toBeUndefined();
    expect(epic.startDateUndefined).toBe(true);
    expect(epic.endDateUndefined).toBe(true);
  });
});

describe('extractGroupEpics', () => {
  it('returns array of epics with `edges->nodes` nesting removed', () => {
    const { edges } = mockGroupEpicsQueryResponse.data.group.epics;
    const extractedEpics = epicUtils.extractGroupEpics(edges);

    expect(extractedEpics.length).toBe(edges.length);
    expect(extractedEpics[0]).toEqual(
      jasmine.objectContaining({
        ...edges[0].node,
        groupName: edges[0].node.group.name,
        groupFullName: edges[0].node.group.fullName,
      }),
    );
  });
});
