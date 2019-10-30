import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'helpers/test_constants';
import createFlash from '~/flash';
import * as actions from 'ee/analytics/cycle_analytics/store/actions';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';
import {
  group,
  cycleAnalyticsData,
  allowedStages as stages,
  groupLabels,
  startDate,
  endDate,
} from '../mock_data';

const stageData = { events: [] };
const error = new Error('Request failed with status code 404');
const groupPath = 'cool-group';
const groupLabelsEndpoint = `/groups/${groupPath}/-/labels`;
const flashErrorMessage = 'There was an error while fetching cycle analytics data.';

describe('Cycle analytics actions', () => {
  let state;
  let mock;

  function shouldFlashAnError(msg = flashErrorMessage) {
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

  describe('fetchGroupLabels', () => {
    beforeEach(() => {
      mock.onGet(groupLabelsEndpoint).replyOnce(200, groupLabels);
    });

    it('dispatches receiveGroupLabels if the request succeeds', done => {
      testAction(
        actions.fetchGroupLabels,
        groupPath,
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
        'this-path-does-not-exist',
        state,
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

        shouldFlashAnError('There was an error fetching label data for the selected group');
      });
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

    it('removes an existing flash error if present', () => {
      const commit = jest.fn();
      const dispatch = jest.fn();
      const stateWithStages = {
        ...state,
        stages,
      };
      createFlash(flashErrorMessage);

      const flashAlert = document.querySelector('.flash-alert');

      expect(flashAlert).toBeVisible();

      actions.receiveCycleAnalyticsDataSuccess({ commit, dispatch, state: stateWithStages });

      expect(flashAlert.style.opacity).toBe('0');
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

      shouldFlashAnError();
    });
  });
});
