import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'helpers/test_constants';
import * as actions from 'ee/analytics/cycle_analytics/store/actions';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';
import { group, cycleAnalyticsData, allowedStages as stages } from '../mock_data';

const stageData = { events: [] };
const error = new Error('Request failed with status code 404');

describe('Cycle analytics actions', () => {
  let state;
  let mock;

  function shouldFlashAnError(msg = 'There was an error while fetching cycle analytics data.') {
    expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(msg);
  }

  beforeEach(() => {
    state = {
      endpoints: {
        cycleAnalyticsData: `${TEST_HOST}/groups/${group.path}/-/cycle_analytics`,
        stageData: `${TEST_HOST}/groups/${group.path}/-/cycle_analytics/events/${cycleAnalyticsData.stats[0].name}.json`,
      },
      stages: [],
    };
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  it.each`
    action                             | type                                   | stateKey                          | payload
    ${'setCycleAnalyticsDataEndpoint'} | ${'SET_CYCLE_ANALYTICS_DATA_ENDPOINT'} | ${'endpoints.cycleAnalyticsData'} | ${'coolGroupName'}
    ${'setStageDataEndpoint'}          | ${'SET_STAGE_DATA_ENDPOINT'}           | ${'endpoints.stageData'}          | ${'new_stage_name'}
    ${'setSelectedGroup'}              | ${'SET_SELECTED_GROUP'}                | ${'selectedGroup'}                | ${'someNewGroup'}
    ${'setSelectedProjects'}           | ${'SET_SELECTED_PROJECTS'}             | ${'selectedProjectIds'}           | ${[10, 20, 30, 40]}
    ${'setSelectedStageName'}          | ${'SET_SELECTED_STAGE_NAME'}           | ${'selectedStageName'}            | ${'someNewGroup'}
    ${'setSelectedTimeframe'}          | ${'SET_SELECTED_TIMEFRAME'}            | ${'dataTimeframe'}                | ${20}
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

  describe('fetchStageData', () => {
    beforeEach(() => {
      mock.onGet(state.endpoints.stageData).replyOnce(200, { events: [] });
    });

    it('dispatches receiveStageDataSuccess with received data on success', done => {
      testAction(
        actions.fetchStageData,
        null,
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
      const brokenState = {
        ...state,
        endpoints: {
          stageData: 'this will break',
        },
      };

      testAction(
        actions.fetchStageData,
        null,
        brokenState,
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

      shouldFlashAnError();
    });
  });

  describe('fetchCycleAnalyticsData', () => {
    beforeEach(() => {
      mock.onGet(state.endpoints.cycleAnalyticsData).replyOnce(200, cycleAnalyticsData);
    });

    it('dispatches receiveCycleAnalyticsDataSuccess with received data', done => {
      testAction(
        actions.fetchCycleAnalyticsData,
        null,
        state,
        [],
        [
          { type: 'requestCycleAnalyticsData' },
          {
            type: 'receiveCycleAnalyticsDataSuccess',
            payload: { ...cycleAnalyticsData },
          },
        ],
        done,
      );
    });

    it('dispatches receiveCycleAnalyticsError on error', done => {
      const brokenState = {
        ...state,
        endpoints: {
          cycleAnalyticsData: 'this will break',
        },
      };

      testAction(
        actions.fetchCycleAnalyticsData,
        null,
        brokenState,
        [],
        [
          { type: 'requestCycleAnalyticsData' },
          {
            type: 'receiveCycleAnalyticsDataError',
            payload: error,
          },
        ],
        done,
      );
    });

    describe('requestCycleAnalyticsData', () => {
      it(`commits the ${types.REQUEST_CYCLE_ANALYTICS_DATA} mutation`, done => {
        testAction(
          actions.requestCycleAnalyticsData,
          { ...cycleAnalyticsData },
          state,
          [
            {
              type: types.REQUEST_CYCLE_ANALYTICS_DATA,
            },
          ],
          [],
          done,
        );
      });
    });
  });

  describe('receiveCycleAnalyticsDataSuccess', () => {
    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
    });
    it(`commits the ${types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS} mutation`, done => {
      testAction(
        actions.receiveCycleAnalyticsDataSuccess,
        { ...cycleAnalyticsData },
        state,
        [
          {
            type: types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS,
            payload: { ...cycleAnalyticsData },
          },
        ],
        [],
        done,
      );
    });

    it("dispatches the 'setStageDataEndpoint' and 'fetchStageData' actions", done => {
      const { slug } = stages[0];
      const stateWithStages = {
        ...state,
        stages,
      };

      testAction(
        actions.receiveCycleAnalyticsDataSuccess,
        { ...cycleAnalyticsData },
        stateWithStages,
        [
          {
            type: types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS,
            payload: { ...cycleAnalyticsData },
          },
        ],
        [{ type: 'setStageDataEndpoint', payload: slug }, { type: 'fetchStageData' }],
        done,
      );
    });

    it('will flash an error when there are no stages', () => {
      [[], null].forEach(emptyStages => {
        actions.receiveCycleAnalyticsDataSuccess(
          {
            commit: () => {},
            state: { stages: emptyStages },
          },
          {},
        );

        shouldFlashAnError();
      });
    });
  });

  describe('receiveCycleAnalyticsDataError', () => {
    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
    });
    it(`commits the ${types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR} mutation`, done => {
      testAction(
        actions.receiveCycleAnalyticsDataError,
        null,
        state,
        [
          {
            type: types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR,
          },
        ],
        [],
        done,
      );
    });

    it('will flash an error', () => {
      actions.receiveCycleAnalyticsDataError(
        {
          commit: () => {},
        },
        {},
      );

      shouldFlashAnError();
    });
  });
});
