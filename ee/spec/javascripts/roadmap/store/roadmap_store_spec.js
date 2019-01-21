import RoadmapStore from 'ee/roadmap/store/roadmap_store';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';

import { PRESET_TYPES, EXTEND_AS } from 'ee/roadmap/constants';
import { mockGroupId, mockTimeframeInitialDate, rawEpics, mockSortedBy } from '../mock_data';

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);

describe('RoadmapStore', () => {
  let store;

  beforeEach(() => {
    store = new RoadmapStore({
      groupId: mockGroupId,
      timeframe: mockTimeframeMonths,
      presetType: PRESET_TYPES.MONTHS,
      sortedBy: mockSortedBy,
    });
  });

  describe('constructor', () => {
    it('initializes default state', () => {
      expect(store.state).toBeDefined();
      expect(Array.isArray(store.state.epics)).toBe(true);
      expect(Array.isArray(store.state.epicIds)).toBe(true);
      expect(store.state.currentGroupId).toBe(mockGroupId);
      expect(store.state.timeframe).toBe(mockTimeframeMonths);
      expect(store.presetType).toBe(PRESET_TYPES.MONTHS);
      expect(store.sortedBy).toBe(mockSortedBy);
      expect(store.timeframeStartDate).toBeDefined();
      expect(store.timeframeEndDate).toBeDefined();
    });
  });

  describe('setEpics', () => {
    it('sets Epics list to state while filtering out Epics with invalid dates', () => {
      spyOn(RoadmapStore, 'filterInvalidEpics').and.callThrough();
      store.setEpics(rawEpics);

      expect(RoadmapStore.filterInvalidEpics).toHaveBeenCalledWith(
        jasmine.objectContaining({
          timeframeStartDate: store.timeframeStartDate,
          timeframeEndDate: store.timeframeEndDate,
          state: store.state,
          epics: rawEpics,
        }),
      );

      expect(store.getEpics().length).toBe(rawEpics.length - 1); // There is only 1 invalid epic
    });
  });

  describe('addEpics', () => {
    beforeEach(() => {
      store.setEpics(rawEpics);
    });

    it('adds new Epics to the epics list within state while filtering out existing epics or epics with invalid dates and sorts the list based on `sortedBy` value', () => {
      spyOn(RoadmapStore, 'filterInvalidEpics');
      const sortEpicsSpy = spyOnDependency(RoadmapStore, 'sortEpics').and.stub();

      const newEpic = Object.assign({}, rawEpics[0], {
        id: 999,
      });

      store.addEpics([newEpic]);

      expect(RoadmapStore.filterInvalidEpics).toHaveBeenCalledWith(
        jasmine.objectContaining({
          timeframeStartDate: store.timeframeStartDate,
          timeframeEndDate: store.timeframeEndDate,
          state: store.state,
          epics: [newEpic],
          newEpic: true,
        }),
      );

      expect(sortEpicsSpy).toHaveBeenCalledWith(jasmine.any(Object), mockSortedBy);

      // rawEpics contain 2 invalid epics but now that we added 1
      // new epic, length will be `rawEpics.length - 1 (invalid) + 1 (new epic)`
      expect(store.getEpics().length).toBe(rawEpics.length);
    });
  });

  describe('getCurrentGroupId', () => {
    it('gets currentGroupId from store state', () => {
      expect(store.getCurrentGroupId()).toBe(mockGroupId);
    });
  });

  describe('getTimeframe', () => {
    it('gets timeframe from store state', () => {
      expect(store.getTimeframe()).toBe(mockTimeframeMonths);
    });
  });

  describe('extendTimeframe', () => {
    beforeEach(() => {
      store.setEpics(rawEpics);
      store.state.timeframe = [];
    });

    it('calls `extendTimeframeForPreset` and prepends items to the timeframe when called with `extendAs` param as `prepend`', () => {
      const extendTimeframeSpy = spyOnDependency(
        RoadmapStore,
        'extendTimeframeForPreset',
      ).and.returnValue([]);
      spyOn(store.state.timeframe, 'unshift');
      spyOn(store, 'initTimeframeThreshold');
      spyOn(RoadmapStore, 'processEpicDates');

      const itemCount = store.extendTimeframe(EXTEND_AS.PREPEND).length;

      expect(extendTimeframeSpy).toHaveBeenCalledWith(jasmine.any(Object));
      expect(store.state.timeframe.unshift).toHaveBeenCalled();
      expect(store.initTimeframeThreshold).toHaveBeenCalled();
      expect(RoadmapStore.processEpicDates).toHaveBeenCalled();
      expect(itemCount).toBe(0);
    });

    it('calls `extendTimeframeForPreset` and appends items to the timeframe when called with `extendAs` param as `append`', () => {
      const extendTimeframeSpy = spyOnDependency(
        RoadmapStore,
        'extendTimeframeForPreset',
      ).and.returnValue([]);
      spyOn(store.state.timeframe, 'push');
      spyOn(store, 'initTimeframeThreshold');
      spyOn(RoadmapStore, 'processEpicDates');

      const itemCount = store.extendTimeframe(EXTEND_AS.APPEND).length;

      expect(extendTimeframeSpy).toHaveBeenCalledWith(jasmine.any(Object));
      expect(store.state.timeframe.push).toHaveBeenCalled();
      expect(store.initTimeframeThreshold).toHaveBeenCalled();
      expect(RoadmapStore.processEpicDates).toHaveBeenCalled();
      expect(itemCount).toBe(0);
    });
  });

  describe('filterInvalidEpics', () => {
    it('returns formatted epics list by filtering out epics with invalid dates', () => {
      spyOn(RoadmapStore, 'formatEpicDetails').and.callThrough();

      const epicsList = RoadmapStore.filterInvalidEpics({
        epics: rawEpics,
        timeframeStartDate: store.timeframeStartDate,
        timeframeEndDate: store.timeframeEndDate,
        state: store.state,
      });

      expect(RoadmapStore.formatEpicDetails).toHaveBeenCalled();

      expect(epicsList.length).toBe(rawEpics.length - 1); // There are is only 1 invalid epic
    });

    it('returns formatted epics list by filtering out existing epics', () => {
      store.setEpics(rawEpics);

      spyOn(RoadmapStore, 'formatEpicDetails').and.callThrough();

      const newEpic = Object.assign({}, rawEpics[0]);

      const epicsList = RoadmapStore.filterInvalidEpics({
        epics: [newEpic],
        timeframeStartDate: store.timeframeStartDate,
        timeframeEndDate: store.timeframeEndDate,
        state: store.state,
      });

      expect(RoadmapStore.formatEpicDetails).toHaveBeenCalled();

      expect(epicsList.length).toBe(0); // No epics are eligible to be added
    });
  });

  describe('formatEpicDetails', () => {
    const rawEpic = rawEpics[0];

    it('returns formatted Epic object from raw Epic object', () => {
      spyOn(RoadmapStore, 'processEpicDates');

      const epic = RoadmapStore.formatEpicDetails(
        rawEpic,
        store.timeframeStartDate,
        store.timeframeEndDate,
      );

      expect(RoadmapStore.processEpicDates).toHaveBeenCalled();
      expect(epic.id).toBe(rawEpic.id);
      expect(epic.name).toBe(rawEpic.name);
      expect(epic.groupId).toBe(rawEpic.group_id);
      expect(epic.groupName).toBe(rawEpic.group_name);
    });

    it('returns formatted Epic object with startDateUndefined and proxy date set when start date is not available', () => {
      const rawEpicWithoutSD = Object.assign({}, rawEpic, {
        start_date: null,
      });
      const epic = RoadmapStore.formatEpicDetails(
        rawEpicWithoutSD,
        store.timeframeStartDate,
        store.timeframeEndDate,
      );

      expect(epic.id).toBe(rawEpic.id);
      expect(epic.startDateUndefined).toBe(true);
      expect(epic.startDate.getTime()).toBe(store.timeframeStartDate.getTime());
    });

    it('returns formatted Epic object with endDateUndefined and proxy date set when end date is not available', () => {
      const rawEpicWithoutED = Object.assign({}, rawEpic, {
        end_date: null,
      });
      const epic = RoadmapStore.formatEpicDetails(
        rawEpicWithoutED,
        store.timeframeStartDate,
        store.timeframeEndDate,
      );

      expect(epic.id).toBe(rawEpic.id);
      expect(epic.endDateUndefined).toBe(true);
      expect(epic.endDate.getTime()).toBe(store.timeframeEndDate.getTime());
    });

    it('returns formatted Epic object with startDateOutOfRange, proxy date and cached original start date set when start date is out of timeframe range', () => {
      const rawStartDate = '2017-1-1';
      const rawEpicSDOut = Object.assign({}, rawEpic, {
        start_date: rawStartDate,
      });
      const epic = RoadmapStore.formatEpicDetails(
        rawEpicSDOut,
        store.timeframeStartDate,
        store.timeframeEndDate,
      );

      expect(epic.id).toBe(rawEpic.id);
      expect(epic.startDateOutOfRange).toBe(true);
      expect(epic.startDate.getTime()).toBe(store.timeframeStartDate.getTime());
      expect(epic.originalStartDate.getTime()).toBe(new Date(rawStartDate).getTime());
    });

    it('returns formatted Epic object with endDateOutOfRange, proxy date and cached original end date set when end date is out of timeframe range', () => {
      const rawEndDate = '2019-1-1';
      const rawEpicEDOut = Object.assign({}, rawEpic, {
        end_date: rawEndDate,
      });
      const epic = RoadmapStore.formatEpicDetails(
        rawEpicEDOut,
        store.timeframeStartDate,
        store.timeframeEndDate,
      );

      expect(epic.id).toBe(rawEpic.id);
      expect(epic.endDateOutOfRange).toBe(true);
      expect(epic.endDate.getTime()).toBe(store.timeframeEndDate.getTime());
      expect(epic.originalEndDate.getTime()).toBe(new Date(rawEndDate).getTime());
    });
  });
});
