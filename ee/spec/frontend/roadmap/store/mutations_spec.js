import mutations from 'ee/roadmap/store/mutations';
import * as types from 'ee/roadmap/store/mutation_types';

import defaultState from 'ee/roadmap/store/state';

import { mockGroupId, basePath, epicsPath, mockSortedBy } from 'ee_jest/roadmap/mock_data';

const getEpic = (epicId, epics) => epics.find(e => e.id === epicId);

describe('Roadmap Store Mutations', () => {
  let state;

  beforeEach(() => {
    state = defaultState();
  });

  describe('SET_INITIAL_DATA', () => {
    it('Should set initial Roadmap data to state', () => {
      const initialData = {
        windowResizeInProgress: false,
        epicsFetchInProgress: false,
        epicsFetchForTimeframeInProgress: false,
        epicsFetchFailure: false,
        epicsFetchResultEmpty: false,
        currentGroupId: mockGroupId,
        sortedBy: mockSortedBy,
        initialEpicsPath: epicsPath,
        defaultInnerHeight: 600,
        extendedTimeframe: [],
        filterQueryString: '',
        epicsState: 'all',
        epicIds: [],
        epics: [],
        basePath,
      };

      mutations[types.SET_INITIAL_DATA](state, initialData);

      expect(state).toEqual(expect.objectContaining(initialData));
    });
  });

  describe('SET_EPICS', () => {
    it('Should provided epics array in state', () => {
      const epics = [{ id: 1 }, { id: 2 }];

      mutations[types.SET_EPICS](state, epics);

      expect(state.epics).toEqual(epics);
    });
  });

  describe('SET_WINDOW_RESIZE_IN_PROGRESS', () => {
    it('Should set value of `state.windowResizeInProgress` based on provided value', () => {
      mutations[types.SET_WINDOW_RESIZE_IN_PROGRESS](state, true);

      expect(state.windowResizeInProgress).toEqual(true);
    });
  });

  describe('UPDATE_EPIC_IDS', () => {
    it('Should insert provided epicId to epicIds array in state', () => {
      mutations[types.UPDATE_EPIC_IDS](state, 22);

      expect(state.epicIds).toHaveLength(1);
      expect(state.epicIds[0]).toBe(22);
    });
  });

  describe('REQUEST_EPICS', () => {
    it('Should set state.epicsFetchInProgress to `true`', () => {
      mutations[types.REQUEST_EPICS](state);

      expect(state.epicsFetchInProgress).toBe(true);
    });
  });

  describe('REQUEST_EPICS_FOR_TIMEFRAME', () => {
    it('Should set state.epicsFetchForTimeframeInProgress to `true`', () => {
      mutations[types.REQUEST_EPICS_FOR_TIMEFRAME](state);

      expect(state.epicsFetchForTimeframeInProgress).toBe(true);
    });
  });

  describe('RECEIVE_EPICS_SUCCESS', () => {
    it('Should set epicsFetchResultEmpty, epics in state based on provided epics array and set epicsFetchInProgress to `false`', () => {
      const epics = [{ id: 1 }, { id: 2 }];

      mutations[types.RECEIVE_EPICS_SUCCESS](state, epics);

      expect(state.epicsFetchResultEmpty).toBe(false);
      expect(state.epics).toEqual(epics);
      expect(state.epicsFetchInProgress).toBe(false);
    });
  });

  describe('RECEIVE_EPICS_FOR_TIMEFRAME_SUCCESS', () => {
    it('Should set epics in state based on provided epics array and set epicsFetchForTimeframeInProgress to `false`', () => {
      const epics = [{ id: 1 }, { id: 2 }];

      mutations[types.RECEIVE_EPICS_FOR_TIMEFRAME_SUCCESS](state, epics);

      expect(state.epics).toEqual(epics);
      expect(state.epicsFetchForTimeframeInProgress).toBe(false);
    });
  });

  describe('RECEIVE_EPICS_FAILURE', () => {
    it('Should set epicsFetchInProgress & epicsFetchForTimeframeInProgress to false and epicsFetchFailure to true', () => {
      mutations[types.RECEIVE_EPICS_FAILURE](state);

      expect(state.epicsFetchInProgress).toBe(false);
      expect(state.epicsFetchForTimeframeInProgress).toBe(false);
      expect(state.epicsFetchFailure).toBe(true);
    });
  });

  describe('PREPEND_TIMEFRAME', () => {
    it('Should set extendedTimeframe to provided extendedTimeframe param and prepend it to timeframe array in state', () => {
      state.timeframe.push('foo');
      const extendedTimeframe = ['bar'];

      mutations[types.PREPEND_TIMEFRAME](state, extendedTimeframe);

      expect(state.extendedTimeframe).toBe(extendedTimeframe);
      expect(state.timeframe[0]).toBe(extendedTimeframe[0]);
    });
  });

  describe('APPEND_TIMEFRAME', () => {
    it('Should set extendedTimeframe to provided extendedTimeframe param and append it to timeframe array in state', () => {
      state.timeframe.push('foo');
      const extendedTimeframe = ['bar'];

      mutations[types.APPEND_TIMEFRAME](state, extendedTimeframe);

      expect(state.extendedTimeframe).toBe(extendedTimeframe);
      expect(state.timeframe[1]).toBe(extendedTimeframe[0]);
    });
  });

  describe('SET_MILESTONES', () => {
    it('Should provided milestones array in state', () => {
      const milestones = [{ id: 1 }, { id: 2 }];

      mutations[types.SET_MILESTONES](state, milestones);

      expect(state.milestones).toEqual(milestones);
    });
  });

  describe('UPDATE_MILESTONE_IDS', () => {
    it('Should update milestoneIds array', () => {
      mutations[types.UPDATE_MILESTONE_IDS](state, [22]);

      expect(state.milestoneIds).toHaveLength(1);
      expect(state.milestoneIds[0]).toBe(22);
    });
  });

  describe('REQUEST_MILESTONES', () => {
    it('Should set state.milestonesFetchInProgress to `true`', () => {
      mutations[types.REQUEST_MILESTONES](state);

      expect(state.milestonesFetchInProgress).toBe(true);
    });
  });

  describe('RECEIVE_MILESTONES_SUCCESS', () => {
    it('Should set milestonesFetchResultEmpty, milestones in state based on provided milestones array and set milestonesFetchInProgress to `false`', () => {
      const milestones = [{ id: 1 }, { id: 2 }];

      mutations[types.RECEIVE_MILESTONES_SUCCESS](state, milestones);

      expect(state.milestonesFetchResultEmpty).toBe(false);
      expect(state.milestones).toEqual(milestones);
      expect(state.milestonesFetchInProgress).toBe(false);
    });
  });

  describe('RECEIVE_MILESTONES_FAILURE', () => {
    it('Should set milestonesFetchInProgress to false and milestonesFetchFailure to true', () => {
      mutations[types.RECEIVE_MILESTONES_FAILURE](state);

      expect(state.milestonesFetchInProgress).toBe(false);
      expect(state.milestonesFetchFailure).toBe(true);
    });
  });

  describe('SET_BUFFER_SIZE', () => {
    it('Should set `bufferSize` in state', () => {
      const bufferSize = 10;

      mutations[types.SET_BUFFER_SIZE](state, bufferSize);

      expect(state.bufferSize).toBe(bufferSize);
    });
  });

  describe('TOGGLE_EXPANDED_EPIC', () => {
    it('should toggle collapsed epic to an expanded epic', () => {
      const epicId = 1;
      const epics = [
        { id: 1, title: 'Collapsed epic', isChildEpicShowing: false },
        { id: 2, title: 'Expanded epic', isChildEpicShowing: true },
      ];

      mutations[types.TOGGLE_EXPANDED_EPIC]({ ...state, epics }, epicId);

      expect(getEpic(epicId, epics).isChildEpicShowing).toBe(true);
    });

    it('should toggle expanded epic to a collapsed epic', () => {
      const epicId = 2;
      const epics = [
        { id: 1, title: 'Collapsed epic', isChildEpicShowing: false },
        { id: 2, title: 'Expanded epic', isChildEpicShowing: true },
      ];

      mutations[types.TOGGLE_EXPANDED_EPIC]({ ...state, epics }, epicId);

      expect(getEpic(epicId, epics).isChildEpicShowing).toBe(false);
    });
  });
});
