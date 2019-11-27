import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
import * as getters from 'ee/analytics/cycle_analytics/store/getters';
import * as actions from 'ee/analytics/cycle_analytics/store/actions';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';
import {
  group,
  cycleAnalyticsData,
  allowedStages as stages,
  groupLabels,
  startDate,
  endDate,
  customizableStagesAndEvents,
} from '../mock_data';

const stageData = { events: [] };
const error = new Error('Request failed with status code 404');
const flashErrorMessage = 'There was an error while fetching cycle analytics data.';
const selectedGroup = { fullPath: group.path };
const [{ id: selectedStageSlug }] = stages;
const endpoints = {
  groupLabels: `/groups/${group.path}/-/labels`,
  cycleAnalyticsData: `/groups/${group.path}/-/cycle_analytics`,
  stageData: `/groups/${group.path}/-/cycle_analytics/events/${selectedStageSlug}.json`,
};

const stageEndpoint = ({ stageId }) => `/-/analytics/cycle_analytics/stages/${stageId}`;

describe('Cycle analytics actions', () => {
  let state;
  let mock;

  function shouldFlashAMessage(msg = flashErrorMessage) {
    expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(msg);
  }

  beforeEach(() => {
    state = {
      stages: [],
      getters,
    };
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    state = { ...state, selectedGroup: null };
  });

  it.each`
    action                   | type                       | stateKey                | payload
    ${'setSelectedGroup'}    | ${'SET_SELECTED_GROUP'}    | ${'selectedGroup'}      | ${'someNewGroup'}
    ${'setSelectedProjects'} | ${'SET_SELECTED_PROJECTS'} | ${'selectedProjectIds'} | ${[10, 20, 30, 40]}
    ${'setSelectedStageId'}  | ${'SET_SELECTED_STAGE_ID'} | ${'selectedStageId'}    | ${'someNewGroup'}
  `('$action should set $stateKey with $payload and type $type', ({ action, type, payload }) => {
    testAction(
      actions[action],
      payload,
      state,
      [
        {
          type,
          payload,
        },
      ],
      [],
    );
  });

  describe('setDateRange', () => {
    it('sets the dates as expected and dispatches fetchCycleAnalyticsData', done => {
      const dispatch = expect.any(Function);

      testAction(
        actions.setDateRange,
        { startDate, endDate },
        state,
        [{ type: types.SET_DATE_RANGE, payload: { startDate, endDate } }],
        [{ type: 'fetchCycleAnalyticsData', payload: { dispatch, state } }],
        done,
      );
    });
  });

  describe('fetchStageData', () => {
    beforeEach(() => {
      state = { ...state, selectedGroup };
      mock.onGet(endpoints.stageData).replyOnce(200, { events: [] });
    });

    it('dispatches receiveStageDataSuccess with received data on success', done => {
      testAction(
        actions.fetchStageData,
        selectedStageSlug,
        state,
        [],
        [
          { type: 'requestStageData' },
          {
            type: 'receiveStageDataSuccess',
            payload: { events: [] },
          },
        ],
        done,
      );
    });

    it('dispatches receiveStageDataError on error', done => {
      testAction(
        actions.fetchStageData,
        null,
        state,
        [],
        [
          { type: 'requestStageData' },
          {
            type: 'receiveStageDataError',
            payload: error,
          },
        ],
        done,
      );
    });

    describe('receiveStageDataSuccess', () => {
      it(`commits the ${types.RECEIVE_STAGE_DATA_SUCCESS} mutation`, done => {
        testAction(
          actions.receiveStageDataSuccess,
          { ...stageData },
          state,
          [{ type: types.RECEIVE_STAGE_DATA_SUCCESS, payload: { events: [] } }],
          [],
          done,
        );
      });
    });
  });

  describe('receiveStageDataError', () => {
    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
    });
    it(`commits the ${types.RECEIVE_STAGE_DATA_ERROR} mutation`, done => {
      testAction(
        actions.receiveStageDataError,
        null,
        state,
        [
          {
            type: types.RECEIVE_STAGE_DATA_ERROR,
          },
        ],
        [],
        done,
      );
    });

    it('will flash an error message', () => {
      actions.receiveStageDataError({
        commit: () => {},
      });

      shouldFlashAMessage('There was an error fetching data for the selected stage');
    });
  });

  describe('fetchGroupLabels', () => {
    beforeEach(() => {
      state = { ...state, selectedGroup };
      mock.onGet(endpoints.groupLabels).replyOnce(200, groupLabels);
    });

    it('dispatches receiveGroupLabels if the request succeeds', done => {
      testAction(
        actions.fetchGroupLabels,
        null,
        state,
        [],
        [
          { type: 'requestGroupLabels' },
          {
            type: 'receiveGroupLabelsSuccess',
            payload: groupLabels,
          },
        ],
        done,
      );
    });

    it('dispatches receiveGroupLabelsError if the request fails', done => {
      testAction(
        actions.fetchGroupLabels,
        null,
        { ...state, selectedGroup: { fullPath: null } },
        [],
        [
          { type: 'requestGroupLabels' },
          {
            type: 'receiveGroupLabelsError',
            payload: error,
          },
        ],
        done,
      );
    });

    describe('receiveGroupLabelsError', () => {
      beforeEach(() => {
        setFixtures('<div class="flash-container"></div>');
      });
      it('flashes an error message if the request fails', () => {
        actions.receiveGroupLabelsError({
          commit: () => {},
        });

        shouldFlashAMessage('There was an error fetching label data for the selected group');
      });
    });
  });

  describe('fetchCycleAnalyticsData', () => {
    function mockFetchCycleAnalyticsAction(overrides = {}) {
      const mocks = {
        requestCycleAnalyticsData:
          overrides.requestCycleAnalyticsData || jest.fn().mockResolvedValue(),
        fetchGroupStagesAndEvents:
          overrides.fetchGroupStagesAndEvents || jest.fn().mockResolvedValue(),
        fetchSummaryData: overrides.fetchSummaryData || jest.fn().mockResolvedValue(),
        receiveCycleAnalyticsDataSuccess:
          overrides.receiveCycleAnalyticsDataSuccess || jest.fn().mockResolvedValue(),
      };
      return {
        mocks,
        mockDispatchContext: jest
          .fn()
          .mockImplementationOnce(mocks.requestCycleAnalyticsData)
          .mockImplementationOnce(mocks.fetchGroupStagesAndEvents)
          .mockImplementationOnce(mocks.fetchSummaryData)
          .mockImplementationOnce(mocks.receiveCycleAnalyticsDataSuccess),
      };
    }

    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
      mock.onGet(endpoints.cycleAnalyticsData).replyOnce(200, cycleAnalyticsData);
      state = { ...state, selectedGroup, startDate, endDate };
    });

    it(`dispatches actions for required cycle analytics data`, done => {
      const { mocks, mockDispatchContext } = mockFetchCycleAnalyticsAction();

      actions
        .fetchCycleAnalyticsData({
          dispatch: mockDispatchContext,
          state: {},
          commit: () => {},
        })
        .then(() => {
          expect(mockDispatchContext).toHaveBeenCalled();
          expect(mocks.requestCycleAnalyticsData).toHaveBeenCalled();
          expect(mocks.fetchGroupStagesAndEvents).toHaveBeenCalled();
          expect(mocks.fetchSummaryData).toHaveBeenCalled();
          expect(mocks.receiveCycleAnalyticsDataSuccess).toHaveBeenCalled();
          done();
        })
        .catch(done.fail);
    });

    it(`displays an error if fetchSummaryData fails`, done => {
      const { mockDispatchContext } = mockFetchCycleAnalyticsAction({
        fetchSummaryData: actions.fetchSummaryData({
          dispatch: jest
            .fn()
            .mockResolvedValueOnce()
            .mockImplementation(actions.receiveSummaryDataError({ commit: () => {} })),
          commit: () => {},
          state: { ...state, endpoints: { cycleAnalyticsData: '/this/is/fake' } },
          getters,
        }),
      });

      actions
        .fetchCycleAnalyticsData({
          dispatch: mockDispatchContext,
          state: {},
          commit: () => {},
        })
        .then(() => {
          shouldFlashAMessage('There was an error while fetching cycle analytics summary data.');
          done();
        })
        .catch(done.fail);
    });

    it(`displays an error if fetchGroupStagesAndEvents fails`, done => {
      const { mockDispatchContext } = mockFetchCycleAnalyticsAction({
        fetchGroupStagesAndEvents: actions.fetchGroupStagesAndEvents({
          dispatch: jest
            .fn()
            .mockResolvedValueOnce()
            .mockImplementation(actions.receiveGroupStagesAndEventsError({ commit: () => {} })),
          commit: () => {},
          state: { ...state, endpoints: { cycleAnalyticsData: '/this/is/fake' } },
          getters,
        }),
      });

      actions
        .fetchCycleAnalyticsData({
          dispatch: mockDispatchContext,
          state: {},
          commit: () => {},
        })
        .then(() => {
          shouldFlashAMessage('There was an error fetching cycle analytics stages.');
          done();
        })
        .catch(done.fail);
    });

    describe('with an existing error', () => {
      beforeEach(() => {
        setFixtures('<div class="flash-container"></div>');
      });

      it('removes an existing flash error if present', done => {
        const { mockDispatchContext } = mockFetchCycleAnalyticsAction();
        createFlash(flashErrorMessage);

        const flashAlert = document.querySelector('.flash-alert');

        expect(flashAlert).toBeVisible();

        actions
          .fetchCycleAnalyticsData({
            dispatch: mockDispatchContext,
            state: {},
            commit: () => {},
          })
          .then(() => {
            expect(flashAlert.style.opacity).toBe('0');
            done();
          })
          .catch(done.fail);
      });
    });

    it("dispatches the 'fetchStageData' action", done => {
      const stateWithStages = {
        ...state,
        stages,
      };

      testAction(
        actions.receiveGroupStagesAndEventsSuccess,
        { ...customizableStagesAndEvents },
        stateWithStages,
        [
          {
            type: types.RECEIVE_GROUP_STAGES_AND_EVENTS_SUCCESS,
            payload: { ...customizableStagesAndEvents },
          },
        ],
        [{ type: 'fetchStageData', payload: selectedStageSlug }],
        done,
      );
    });

    it('will flash an error when there are no stages', () => {
      [[], null].forEach(emptyStages => {
        actions.receiveGroupStagesAndEventsSuccess(
          {
            commit: () => {},
            state: { stages: emptyStages },
          },
          {},
        );

        shouldFlashAMessage();
      });
    });
  });

  describe('receiveCycleAnalyticsDataError', () => {
    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
    });

    it(`commits the ${types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR} mutation on a 403 response`, done => {
      const response = { status: 403 };
      testAction(
        actions.receiveCycleAnalyticsDataError,
        { response },
        state,
        [
          {
            type: types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR,
            payload: response.status,
          },
        ],
        [],
        done,
      );
    });

    it(`commits the ${types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR} mutation on a non 403 error response`, done => {
      const response = { status: 500 };
      testAction(
        actions.receiveCycleAnalyticsDataError,
        { response },
        state,
        [
          {
            type: types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR,
            payload: response.status,
          },
        ],
        [],
        done,
      );
    });

    it('will flash an error when the response is not 403', () => {
      const response = { status: 500 };
      actions.receiveCycleAnalyticsDataError(
        {
          commit: () => {},
        },
        { response },
      );

      shouldFlashAMessage();
    });
  });

  describe('receiveGroupStagesAndEventsSuccess', () => {
    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
    });
    it(`commits the ${types.RECEIVE_GROUP_STAGES_AND_EVENTS_SUCCESS} mutation`, done => {
      testAction(
        actions.receiveGroupStagesAndEventsSuccess,
        { ...customizableStagesAndEvents },
        state,
        [
          {
            type: types.RECEIVE_GROUP_STAGES_AND_EVENTS_SUCCESS,
            payload: { ...customizableStagesAndEvents },
          },
        ],
        [],
        done,
      );
    });

    it("dispatches the 'fetchStageData' actions", done => {
      const stateWithStages = {
        ...state,
        stages,
      };

      testAction(
        actions.receiveGroupStagesAndEventsSuccess,
        { ...customizableStagesAndEvents },
        stateWithStages,
        [
          {
            type: types.RECEIVE_GROUP_STAGES_AND_EVENTS_SUCCESS,
            payload: { ...customizableStagesAndEvents },
          },
        ],
        [{ type: 'fetchStageData', payload: selectedStageSlug }],
        done,
      );
    });

    it('will flash an error when there are no stages', () => {
      [[], null].forEach(emptyStages => {
        actions.receiveGroupStagesAndEventsSuccess(
          {
            commit: () => {},
            state: { stages: emptyStages },
          },
          {},
        );
      });

      shouldFlashAMessage();
    });
  });

  describe('updateStage', () => {
    const stageId = 'cool-stage';
    const payload = { hidden: true };

    beforeEach(() => {
      mock.onPut(stageEndpoint({ stageId }), payload).replyOnce(200, payload);
      state = { selectedGroup };
    });

    it('dispatches receiveUpdateStageSuccess with put request response data', done => {
      testAction(
        actions.updateStage,
        {
          id: stageId,
          ...payload,
        },
        state,
        [],
        [
          { type: 'requestUpdateStage' },
          {
            type: 'receiveUpdateStageSuccess',
            payload,
          },
        ],
        done,
      );
    });

    describe('with a failed request', () => {
      beforeEach(() => {
        setFixtures('<div class="flash-container"></div>');
        mock = new MockAdapter(axios);
        mock.onPut(stageEndpoint({ stageId })).replyOnce(404);
      });

      it('dispatches receiveUpdateStageError', done => {
        testAction(
          actions.updateStage,
          {
            id: stageId,
            ...payload,
          },
          state,
          [],
          [
            { type: 'requestUpdateStage' },
            {
              type: 'receiveUpdateStageError',
              payload: error,
            },
          ],
          done,
        );
      });

      it('flashes an error message', done => {
        actions.receiveUpdateStageError(
          {
            commit: () => {},
            state,
          },
          {},
        );

        shouldFlashAMessage('There was a problem saving your custom stage, please try again');
        done();
      });
    });
  });

  describe('removeStage', () => {
    const stageId = 'cool-stage';

    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
      mock.onDelete(stageEndpoint({ stageId })).replyOnce(200);
      state = { selectedGroup };
    });

    it('dispatches receiveRemoveStageSuccess with put request response data', done => {
      testAction(
        actions.removeStage,
        stageId,
        state,
        [],
        [
          { type: 'requestRemoveStage' },
          {
            type: 'receiveRemoveStageSuccess',
          },
        ],
        done,
      );
    });

    describe('with a failed request', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios);
        mock.onDelete(stageEndpoint({ stageId })).replyOnce(404);
      });

      it('dispatches receiveRemoveStageError', done => {
        testAction(
          actions.removeStage,
          stageId,
          state,
          [],
          [
            { type: 'requestRemoveStage' },
            {
              type: 'receiveRemoveStageError',
              payload: error,
            },
          ],
          done,
        );
      });

      it('flashes an error message', done => {
        actions.receiveRemoveStageError(
          {
            commit: () => {},
            state,
          },
          {},
        );

        shouldFlashAMessage('There was an error removing your custom stage, please try again');
        done();
      });
    });
  });

  describe('receiveRemoveStageSuccess', () => {
    const stageId = 'cool-stage';

    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
      mock.onDelete(stageEndpoint({ stageId })).replyOnce(200);
      state = { selectedGroup };
    });

    it('dispatches fetchCycleAnalyticsData', done => {
      testAction(
        actions.receiveRemoveStageSuccess,
        stageId,
        state,
        [{ type: 'RECEIVE_REMOVE_STAGE_RESPONSE' }],
        [{ type: 'fetchCycleAnalyticsData' }],
        done,
      );
    });

    it('flashes a success message', done => {
      actions.receiveRemoveStageSuccess(
        {
          dispatch: () => {},
          commit: () => {},
          state,
        },
        {},
      );

      shouldFlashAMessage('Stage removed');
      done();
    });
  });
});
