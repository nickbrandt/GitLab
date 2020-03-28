import MockAdapter from 'axios-mock-adapter';

import * as actions from 'ee/roadmap/store/actions';
import * as types from 'ee/roadmap/store/mutation_types';

import defaultState from 'ee/roadmap/store/state';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';
import * as epicUtils from 'ee/roadmap/utils/epic_utils';
import * as roadmapItemUtils from 'ee/roadmap/utils/roadmap_item_utils';
import { PRESET_TYPES, EXTEND_AS } from 'ee/roadmap/constants';
import groupEpics from 'ee/roadmap/queries/groupEpics.query.graphql';
import groupMilestones from 'ee/roadmap/queries/groupMilestones.query.graphql';
import epicChildEpics from 'ee/roadmap/queries/epicChildEpics.query.graphql';

import testAction from 'spec/helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';

import {
  mockGroupId,
  basePath,
  epicsPath,
  mockTimeframeInitialDate,
  mockTimeframeMonthsPrepend,
  mockTimeframeMonthsAppend,
  rawEpics,
  mockRawEpic,
  mockFormattedEpic,
  mockSortedBy,
  mockGroupEpicsQueryResponse,
  mockEpicChildEpicsQueryResponse,
  mockGroupMilestonesQueryResponse,
  rawMilestones,
  mockMilestone,
  mockFormattedMilestone,
} from '../mock_data';

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);

describe('Roadmap Vuex Actions', () => {
  const timeframeStartDate = mockTimeframeMonths[0];
  const timeframeEndDate = mockTimeframeMonths[mockTimeframeMonths.length - 1];
  let state;

  beforeEach(() => {
    state = Object.assign({}, defaultState(), {
      groupId: mockGroupId,
      timeframe: mockTimeframeMonths,
      presetType: PRESET_TYPES.MONTHS,
      sortedBy: mockSortedBy,
      initialEpicsPath: epicsPath,
      filterQueryString: '',
      basePath,
      timeframeStartDate,
      timeframeEndDate,
    });
  });

  describe('setInitialData', () => {
    it('should set initial roadmap props', done => {
      const mockRoadmap = {
        foo: 'bar',
        bar: 'baz',
      };

      testAction(
        actions.setInitialData,
        mockRoadmap,
        {},
        [{ type: types.SET_INITIAL_DATA, payload: mockRoadmap }],
        [],
        done,
      );
    });
  });

  describe('setWindowResizeInProgress', () => {
    it('should set value of `state.windowResizeInProgress` based on provided value', done => {
      testAction(
        actions.setWindowResizeInProgress,
        true,
        state,
        [{ type: types.SET_WINDOW_RESIZE_IN_PROGRESS, payload: true }],
        [],
        done,
      );
    });
  });

  describe('fetchGroupEpics', () => {
    let mockState;
    let expectedVariables;

    beforeEach(() => {
      mockState = {
        fullPath: 'gitlab-org',
        epicsState: 'all',
        sortedBy: 'start_date_asc',
        presetType: PRESET_TYPES.MONTHS,
        filterParams: {},
        timeframe: mockTimeframeMonths,
      };

      expectedVariables = {
        fullPath: 'gitlab-org',
        state: mockState.epicsState,
        sort: mockState.sortedBy,
        startDate: '2017-11-1',
        dueDate: '2018-6-30',
      };
    });

    it('should fetch Group Epics using GraphQL client when epicIid is not present in state', done => {
      spyOn(epicUtils.gqClient, 'query').and.returnValue(
        Promise.resolve({
          data: mockGroupEpicsQueryResponse.data,
        }),
      );

      actions
        .fetchGroupEpics(mockState)
        .then(() => {
          expect(epicUtils.gqClient.query).toHaveBeenCalledWith({
            query: groupEpics,
            variables: expectedVariables,
          });
        })
        .then(done)
        .catch(done.fail);
    });

    it('should fetch child Epics of an Epic using GraphQL client when epicIid is present in state', done => {
      spyOn(epicUtils.gqClient, 'query').and.returnValue(
        Promise.resolve({
          data: mockEpicChildEpicsQueryResponse.data,
        }),
      );

      mockState.epicIid = '1';

      actions
        .fetchGroupEpics(mockState)
        .then(() => {
          expect(epicUtils.gqClient.query).toHaveBeenCalledWith({
            query: epicChildEpics,
            variables: {
              iid: '1',
              ...expectedVariables,
            },
          });
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('requestEpics', () => {
    it('should set `epicsFetchInProgress` to true', done => {
      testAction(actions.requestEpics, {}, state, [{ type: 'REQUEST_EPICS' }], [], done);
    });
  });

  describe('requestEpicsForTimeframe', () => {
    it('should set `epicsFetchForTimeframeInProgress` to true', done => {
      testAction(
        actions.requestEpicsForTimeframe,
        {},
        state,
        [{ type: types.REQUEST_EPICS_FOR_TIMEFRAME }],
        [],
        done,
      );
    });
  });

  describe('receiveEpicsSuccess', () => {
    it('should set formatted epics array and epicId to IDs array in state based on provided epics list', done => {
      testAction(
        actions.receiveEpicsSuccess,
        {
          rawEpics: [
            Object.assign({}, mockRawEpic, {
              start_date: '2017-12-31',
              end_date: '2018-2-15',
            }),
          ],
        },
        state,
        [
          { type: types.UPDATE_EPIC_IDS, payload: mockRawEpic.id },
          {
            type: types.RECEIVE_EPICS_SUCCESS,
            payload: [
              Object.assign({}, mockFormattedEpic, {
                startDateOutOfRange: false,
                endDateOutOfRange: false,
                startDate: new Date(2017, 11, 31),
                originalStartDate: new Date(2017, 11, 31),
                endDate: new Date(2018, 1, 15),
                originalEndDate: new Date(2018, 1, 15),
              }),
            ],
          },
        ],
        [],
        done,
      );
    });

    it('should set formatted epics array and epicId to IDs array in state based on provided epics list when timeframe was extended', done => {
      testAction(
        actions.receiveEpicsSuccess,
        { rawEpics: [mockRawEpic], newEpic: true, timeframeExtended: true },
        state,
        [
          { type: types.UPDATE_EPIC_IDS, payload: mockRawEpic.id },
          {
            type: types.RECEIVE_EPICS_FOR_TIMEFRAME_SUCCESS,
            payload: [Object.assign({}, mockFormattedEpic, { newEpic: true })],
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveEpicsFailure', () => {
    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
    });

    it('should set epicsFetchInProgress, epicsFetchForTimeframeInProgress to false and epicsFetchFailure to true', done => {
      testAction(
        actions.receiveEpicsFailure,
        {},
        state,
        [{ type: types.RECEIVE_EPICS_FAILURE }],
        [],
        done,
      );
    });

    it('should show flash error', () => {
      actions.receiveEpicsFailure({ commit: () => {} });

      expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
        'Something went wrong while fetching epics',
      );
    });
  });

  describe('fetchEpics', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('should dispatch requestEpics and receiveEpicsSuccess when request is successful', done => {
        mock.onGet(epicsPath).replyOnce(200, rawEpics);

        testAction(
          actions.fetchEpics,
          null,
          state,
          [],
          [
            {
              type: 'requestEpics',
            },
            {
              type: 'receiveEpicsSuccess',
              payload: { rawEpics },
            },
          ],
          done,
        );
      });
    });

    describe('failure', () => {
      it('should dispatch requestEpics and receiveEpicsFailure when request fails', done => {
        mock.onGet(epicsPath).replyOnce(500, {});

        testAction(
          actions.fetchEpics,
          null,
          state,
          [],
          [
            {
              type: 'requestEpics',
            },
            {
              type: 'receiveEpicsFailure',
            },
          ],
          done,
        );
      });
    });
  });

  describe('fetchEpicsForTimeframe', () => {
    const mockEpicsPath =
      '/groups/gitlab-org/-/epics.json?state=&start_date=2017-11-1&end_date=2018-6-30';
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('should dispatch requestEpicsForTimeframe and receiveEpicsSuccess when request is successful', done => {
        mock.onGet(mockEpicsPath).replyOnce(200, rawEpics);

        testAction(
          actions.fetchEpicsForTimeframe,
          { timeframe: mockTimeframeMonths },
          state,
          [],
          [
            {
              type: 'requestEpicsForTimeframe',
            },
            {
              type: 'receiveEpicsSuccess',
              payload: { rawEpics, newEpic: true, timeframeExtended: true },
            },
          ],
          done,
        );
      });
    });

    describe('failure', () => {
      it('should dispatch requestEpicsForTimeframe and requestEpicsFailure when request fails', done => {
        mock.onGet(mockEpicsPath).replyOnce(500, {});

        testAction(
          actions.fetchEpicsForTimeframe,
          { timeframe: mockTimeframeMonths },
          state,
          [],
          [
            {
              type: 'requestEpicsForTimeframe',
            },
            {
              type: 'receiveEpicsFailure',
            },
          ],
          done,
        );
      });
    });
  });

  describe('extendTimeframe', () => {
    it('should prepend to timeframe when called with extend type prepend', done => {
      testAction(
        actions.extendTimeframe,
        { extendAs: EXTEND_AS.PREPEND },
        state,
        [{ type: types.PREPEND_TIMEFRAME, payload: mockTimeframeMonthsPrepend }],
        [],
        done,
      );
    });

    it('should append to timeframe when called with extend type append', done => {
      testAction(
        actions.extendTimeframe,
        { extendAs: EXTEND_AS.APPEND },
        state,
        [{ type: types.APPEND_TIMEFRAME, payload: mockTimeframeMonthsAppend }],
        [],
        done,
      );
    });
  });

  describe('refreshEpicDates', () => {
    it('should update epics after refreshing epic dates to match with updated timeframe', done => {
      const epics = rawEpics.map(epic =>
        roadmapItemUtils.formatRoadmapItemDetails(
          epic,
          state.timeframeStartDate,
          state.timeframeEndDate,
        ),
      );

      testAction(
        actions.refreshEpicDates,
        {},
        { ...state, timeframe: mockTimeframeMonths.concat(mockTimeframeMonthsAppend), epics },
        [{ type: types.SET_EPICS, payload: epics }],
        [],
        done,
      );
    });
  });

  describe('setBufferSize', () => {
    it('should set bufferSize in store state', done => {
      testAction(
        actions.setBufferSize,
        10,
        state,
        [{ type: types.SET_BUFFER_SIZE, payload: 10 }],
        [],
        done,
      );
    });
  });

  describe('fetchGroupMilestones', () => {
    let mockState;
    let expectedVariables;

    beforeEach(() => {
      mockState = {
        fullPath: 'gitlab-org',
        milestonessState: 'active',
        presetType: PRESET_TYPES.MONTHS,
        timeframe: mockTimeframeMonths,
      };

      expectedVariables = {
        fullPath: 'gitlab-org',
        state: mockState.milestonessState,
        startDate: '2017-11-1',
        dueDate: '2018-6-30',
      };
    });

    it('should fetch Group Milestones using GraphQL client when milestoneIid is not present in state', done => {
      spyOn(epicUtils.gqClient, 'query').and.returnValue(
        Promise.resolve({
          data: mockGroupMilestonesQueryResponse.data,
        }),
      );

      actions
        .fetchGroupMilestones(mockState)
        .then(() => {
          expect(epicUtils.gqClient.query).toHaveBeenCalledWith({
            query: groupMilestones,
            variables: expectedVariables,
          });
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('requestMilestones', () => {
    it('should set `milestonesFetchInProgress` to true', done => {
      testAction(actions.requestMilestones, {}, state, [{ type: 'REQUEST_MILESTONES' }], [], done);
    });
  });

  describe('fetchMilestones', () => {
    describe('success', () => {
      it('should dispatch requestMilestones and receiveMilestonesSuccess when request is successful', done => {
        spyOn(epicUtils.gqClient, 'query').and.returnValue(
          Promise.resolve({
            data: mockGroupMilestonesQueryResponse.data,
          }),
        );

        testAction(
          actions.fetchMilestones,
          null,
          state,
          [],
          [
            {
              type: 'requestMilestones',
            },
            {
              type: 'receiveMilestonesSuccess',
              payload: { rawMilestones },
            },
          ],
          done,
        );
      });
    });

    describe('failure', () => {
      it('should dispatch requestMilestones and receiveMilestonesFailure when request fails', done => {
        testAction(
          actions.fetchMilestones,
          null,
          state,
          [],
          [
            {
              type: 'requestMilestones',
            },
            {
              type: 'receiveMilestonesFailure',
            },
          ],
          done,
        );
      });
    });
  });

  describe('receiveMilestonesSuccess', () => {
    it('should set formatted milestones array and milestoneId to IDs array in state based on provided milestones list', done => {
      testAction(
        actions.receiveMilestonesSuccess,
        {
          rawMilestones: [
            Object.assign({}, mockMilestone, {
              start_date: '2017-12-31',
              end_date: '2018-2-15',
            }),
          ],
        },
        state,
        [
          { type: types.UPDATE_MILESTONE_IDS, payload: [mockMilestone.id] },
          {
            type: types.RECEIVE_MILESTONES_SUCCESS,
            payload: [
              Object.assign({}, mockFormattedMilestone, {
                startDateOutOfRange: false,
                endDateOutOfRange: false,
                startDate: new Date(2017, 11, 31),
                originalStartDate: new Date(2017, 11, 31),
                endDate: new Date(2018, 1, 15),
                originalEndDate: new Date(2018, 1, 15),
              }),
            ],
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveMilestonesFailure', () => {
    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
    });

    it('should set milestonesFetchInProgress to false and milestonesFetchFailure to true', done => {
      testAction(
        actions.receiveMilestonesFailure,
        {},
        state,
        [{ type: types.RECEIVE_MILESTONES_FAILURE }],
        [],
        done,
      );
    });

    it('should show flash error', () => {
      actions.receiveMilestonesFailure({ commit: () => {} });

      expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
        'Something went wrong while fetching milestones',
      );
    });
  });

  describe('refreshMilestoneDates', () => {
    it('should update milestones after refreshing milestone dates to match with updated timeframe', done => {
      const milestones = rawMilestones.map(milestone =>
        roadmapItemUtils.formatRoadmapItemDetails(
          milestone,
          state.timeframeStartDate,
          state.timeframeEndDate,
        ),
      );

      testAction(
        actions.refreshMilestoneDates,
        {},
        { ...state, timeframe: mockTimeframeMonths.concat(mockTimeframeMonthsAppend), milestones },
        [{ type: types.SET_MILESTONES, payload: milestones }],
        [],
        done,
      );
    });
  });
});
