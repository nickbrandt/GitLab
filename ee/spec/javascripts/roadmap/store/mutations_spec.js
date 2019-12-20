import mutations from 'ee/roadmap/store/mutations';
import * as types from 'ee/roadmap/store/mutation_types';

import defaultState from 'ee/roadmap/store/state';

import { mockGroupId, basePath, epicsPath, mockSortedBy } from '../mock_data';

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

      expect(state).toEqual(jasmine.objectContaining(initialData));
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

      expect(state.epicIds.length).toBe(1);
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

  describe('SET_BUFFER_SIZE', () => {
    it('Should set `bufferSize` in state', () => {
      const bufferSize = 10;

      mutations[types.SET_BUFFER_SIZE](state, bufferSize);

      expect(state.bufferSize).toBe(bufferSize);
    });
  });
});
