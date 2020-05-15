import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as getters from 'ee/analytics/cycle_analytics/store/getters';
import * as actions from 'ee/analytics/cycle_analytics/store/actions';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';
import createFlash from '~/flash';
import httpStatusCodes from '~/lib/utils/http_status';
import {
  selectedGroup,
  allowedStages as stages,
  startDate,
  endDate,
  customizableStagesAndEvents,
  endpoints,
} from '../mock_data';

const stageData = { events: [] };
const error = new Error(`Request failed with status code ${httpStatusCodes.NOT_FOUND}`);
const flashErrorMessage = 'There was an error while fetching value stream analytics data.';
const [selectedStage] = stages;
const selectedStageSlug = selectedStage.slug;

const stageEndpoint = ({ stageId }) =>
  `/groups/${selectedGroup.fullPath}/-/analytics/value_stream_analytics/stages/${stageId}`;

jest.mock('~/flash');

describe('Cycle analytics actions', () => {
  let state;
  let mock;

  const shouldFlashAMessage = (msg, type = null) => {
    const args = type ? [msg, type] : [msg];
    expect(createFlash).toHaveBeenCalledWith(...args);
  };

  beforeEach(() => {
    state = {
      startDate,
      endDate,
      stages: [],
      featureFlags: {
        hasDurationChart: true,
        hasDurationChartMedian: true,
      },
    };
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    state = { ...state, selectedGroup: null };
  });

  it.each`
    action                   | type                       | stateKey                | payload
    ${'setFeatureFlags'}     | ${'SET_FEATURE_FLAGS'}     | ${'featureFlags'}       | ${{ hasDurationChart: true }}
    ${'setSelectedGroup'}    | ${'SET_SELECTED_GROUP'}    | ${'selectedGroup'}      | ${'someNewGroup'}
    ${'setSelectedProjects'} | ${'SET_SELECTED_PROJECTS'} | ${'selectedProjectIds'} | ${[10, 20, 30, 40]}
    ${'setSelectedStage'}    | ${'SET_SELECTED_STAGE'}    | ${'selectedStage'}      | ${{ id: 'someStageId' }}
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
    const payload = { startDate, endDate };

    it('dispatches the fetchCycleAnalyticsData action', () => {
      return testAction(
        actions.setDateRange,
        payload,
        state,
        [{ type: types.SET_DATE_RANGE, payload: { startDate, endDate } }],
        [{ type: 'fetchCycleAnalyticsData' }],
      );
    });
  });

  describe('fetchStageData', () => {
    beforeEach(() => {
      state = { ...state, selectedGroup };
      mock = new MockAdapter(axios);
      mock.onGet(endpoints.stageData).reply(200, { events: [] });
    });

    it('dispatches receiveStageDataSuccess with received data on success', () => {
      return testAction(
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
      );
    });

    describe('with a failing request', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios);
        mock.onGet(endpoints.stageData).replyOnce(httpStatusCodes.NOT_FOUND, { error });
      });

      it('dispatches receiveStageDataError on error', () => {
        return testAction(
          actions.fetchStageData,
          selectedStage,
          state,
          [],
          [
            {
              type: 'requestStageData',
            },
            {
              type: 'receiveStageDataError',
              payload: error,
            },
          ],
        );
      });
    });

    describe('receiveStageDataSuccess', () => {
      it(`commits the ${types.RECEIVE_STAGE_DATA_SUCCESS} mutation`, () => {
        return testAction(
          actions.receiveStageDataSuccess,
          { ...stageData },
          state,
          [{ type: types.RECEIVE_STAGE_DATA_SUCCESS, payload: { events: [] } }],
          [],
        );
      });
    });
  });

  describe('receiveStageDataError', () => {
    beforeEach(() => {});
    it(`commits the ${types.RECEIVE_STAGE_DATA_ERROR} mutation`, () => {
      return testAction(
        actions.receiveStageDataError,
        null,
        state,
        [
          {
            type: types.RECEIVE_STAGE_DATA_ERROR,
          },
        ],
        [],
      );
    });

    it('will flash an error message', () => {
      actions.receiveStageDataError({ commit: () => {} });
      shouldFlashAMessage('There was an error fetching data for the selected stage');
    });
  });

  describe('fetchCycleAnalyticsData', () => {
    function mockFetchCycleAnalyticsAction(overrides = {}) {
      const mocks = {
        requestCycleAnalyticsData:
          overrides.requestCycleAnalyticsData || jest.fn().mockResolvedValue(),
        fetchStageMedianValues: overrides.fetchStageMedianValues || jest.fn().mockResolvedValue(),
        fetchGroupStagesAndEvents:
          overrides.fetchGroupStagesAndEvents || jest.fn().mockResolvedValue(),
        receiveCycleAnalyticsDataSuccess:
          overrides.receiveCycleAnalyticsDataSuccess || jest.fn().mockResolvedValue(),
      };
      return {
        mocks,
        mockDispatchContext: jest
          .fn()
          .mockImplementationOnce(mocks.requestCycleAnalyticsData)
          .mockImplementationOnce(mocks.fetchGroupStagesAndEvents)
          .mockImplementationOnce(mocks.fetchStageMedianValues)
          .mockImplementationOnce(mocks.receiveCycleAnalyticsDataSuccess),
      };
    }

    beforeEach(() => {
      state = { ...state, selectedGroup, startDate, endDate };
    });

    it(`dispatches actions for required value stream analytics analytics data`, () => {
      testAction(
        actions.fetchCycleAnalyticsData,
        state,
        null,
        [],
        [
          { type: 'requestCycleAnalyticsData' },
          { type: 'fetchGroupStagesAndEvents' },
          { type: 'fetchStageMedianValues' },
          { type: 'receiveCycleAnalyticsDataSuccess' },
        ],
      );
    });

    it(`displays an error if fetchStageMedianValues fails`, () => {
      const { mockDispatchContext } = mockFetchCycleAnalyticsAction({
        fetchStageMedianValues: actions.fetchStageMedianValues({
          dispatch: jest
            .fn()
            .mockResolvedValueOnce()
            .mockImplementation(actions.receiveStageMedianValuesError({ commit: () => {} })),
          commit: () => {},
          state: { ...state },
          getters,
        }),
      });

      return actions
        .fetchCycleAnalyticsData({
          dispatch: mockDispatchContext,
          state: {},
          commit: () => {},
        })
        .then(() => {
          shouldFlashAMessage('There was an error fetching median data for stages');
        });
    });

    it(`displays an error if fetchGroupStagesAndEvents fails`, () => {
      const { mockDispatchContext } = mockFetchCycleAnalyticsAction({
        fetchGroupStagesAndEvents: actions.fetchGroupStagesAndEvents({
          dispatch: jest
            .fn()
            .mockResolvedValueOnce()
            .mockImplementation(actions.receiveGroupStagesError({ commit: () => {} })),
          commit: () => {},
          state: { ...state },
          getters,
        }),
      });

      return actions
        .fetchCycleAnalyticsData({
          dispatch: mockDispatchContext,
          state: {},
          commit: () => {},
        })
        .then(() => {
          shouldFlashAMessage('There was an error fetching value stream analytics stages.');
        });
    });
  });

  describe('receiveCycleAnalyticsDataError', () => {
    beforeEach(() => {});

    it(`commits the ${types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR} mutation on a 403 response`, () => {
      const response = { status: 403 };
      return testAction(
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
      );
    });

    it(`commits the ${types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR} mutation on a non 403 error response`, () => {
      const response = { status: 500 };
      return testAction(
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

      shouldFlashAMessage(flashErrorMessage);
    });
  });

  describe('receiveGroupStagesSuccess', () => {
    beforeEach(() => {});

    it(`commits the ${types.RECEIVE_GROUP_STAGES_SUCCESS} mutation and dispatches 'setDefaultSelectedStage'`, () => {
      return testAction(
        actions.receiveGroupStagesSuccess,
        { ...customizableStagesAndEvents.stages },
        state,
        [
          {
            type: types.RECEIVE_GROUP_STAGES_SUCCESS,
            payload: { ...customizableStagesAndEvents.stages },
          },
        ],
        [{ type: 'setDefaultSelectedStage' }],
      );
    });
  });

  describe('setDefaultSelectedStage', () => {
    it("dispatches the 'fetchStageData' action", () => {
      return testAction(
        actions.setDefaultSelectedStage,
        null,
        {
          activeStages: stages,
        },
        [],
        [
          { type: 'setSelectedStage', payload: selectedStage },
          { type: 'fetchStageData', payload: selectedStageSlug },
        ],
      );
    });

    it.each`
      data
      ${[]}
      ${null}
    `('with $data will flash an error', ({ data }) => {
      actions.setDefaultSelectedStage({ getters: { activeStages: data }, dispatch: () => {} }, {});
      shouldFlashAMessage(flashErrorMessage);
    });

    it('will select the first active stage', () => {
      stages[0].hidden = true;
      return testAction(
        actions.setDefaultSelectedStage,
        null,
        {
          activeStages: getters.activeStages({ stages }),
        },
        [],
        [
          { type: 'setSelectedStage', payload: stages[1] },
          { type: 'fetchStageData', payload: stages[1].slug },
        ],
      );
    });
  });

  describe('updateStage', () => {
    const stageId = 'cool-stage';
    const payload = { hidden: true };

    beforeEach(() => {
      mock.onPut(stageEndpoint({ stageId }), payload).replyOnce(200, payload);
      state = { selectedGroup };
    });

    it('dispatches receiveUpdateStageSuccess and customStages/setSavingCustomStage', () => {
      return testAction(
        actions.updateStage,
        {
          id: stageId,
          ...payload,
        },
        state,
        [],
        [
          { type: 'requestUpdateStage' },
          { type: 'customStages/setSavingCustomStage' },
          {
            type: 'receiveUpdateStageSuccess',
            payload,
          },
        ],
      );
    });

    describe('with a failed request', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios);
        mock.onPut(stageEndpoint({ stageId })).replyOnce(httpStatusCodes.NOT_FOUND);
      });

      it('dispatches receiveUpdateStageError', () => {
        const data = {
          id: stageId,
          name: 'issue',
          ...payload,
        };
        return testAction(
          actions.updateStage,
          data,
          state,
          [],
          [
            { type: 'requestUpdateStage' },
            { type: 'customStages/setSavingCustomStage' },
            {
              type: 'receiveUpdateStageError',
              payload: {
                status: httpStatusCodes.NOT_FOUND,
                data,
              },
            },
          ],
        );
      });

      it('flashes an error if the stage name already exists', () => {
        return actions
          .receiveUpdateStageError(
            {
              commit: () => {},
              dispatch: () => Promise.resolve(),
              state,
            },
            {
              status: httpStatusCodes.UNPROCESSABLE_ENTITY,
              responseData: {
                errors: { name: ['is reserved'] },
              },
              data: {
                name: stageId,
              },
            },
          )
          .then(() => {
            shouldFlashAMessage(`'${stageId}' stage already exists`);
          });
      });

      it('flashes an error message', () => {
        return actions
          .receiveUpdateStageError(
            {
              dispatch: () => Promise.resolve(),
              commit: () => {},
              state,
            },
            { status: httpStatusCodes.BAD_REQUEST },
          )
          .then(() => {
            shouldFlashAMessage('There was a problem saving your custom stage, please try again');
          });
      });
    });

    describe('receiveUpdateStageSuccess', () => {
      const response = {
        title: 'NEW - COOL',
      };

      it('will dispatch fetchGroupStagesAndEvents', () =>
        testAction(
          actions.receiveUpdateStageSuccess,
          response,
          state,
          [{ type: types.RECEIVE_UPDATE_STAGE_SUCCESS }],
          [
            { type: 'fetchGroupStagesAndEvents' },
            { type: 'customStages/showEditForm', payload: response },
          ],
        ));

      it('will flash a success message', () => {
        return actions
          .receiveUpdateStageSuccess(
            {
              dispatch: () => {},
              commit: () => {},
            },
            response,
          )
          .then(() => {
            shouldFlashAMessage('Stage data updated', 'notice');
          });
      });

      describe('with an error', () => {
        it('will flash an error message', () =>
          actions
            .receiveUpdateStageSuccess(
              {
                dispatch: () => Promise.reject(),
                commit: () => {},
              },
              response,
            )
            .then(() => {
              shouldFlashAMessage('There was a problem refreshing the data, please try again');
            }));
      });
    });
  });

  describe('removeStage', () => {
    const stageId = 'cool-stage';

    beforeEach(() => {
      mock.onDelete(stageEndpoint({ stageId })).replyOnce(200);
      state = { selectedGroup };
    });

    it('dispatches receiveRemoveStageSuccess with put request response data', () => {
      return testAction(
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
      );
    });

    describe('with a failed request', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios);
        mock.onDelete(stageEndpoint({ stageId })).replyOnce(httpStatusCodes.NOT_FOUND);
      });

      it('dispatches receiveRemoveStageError', () => {
        return testAction(
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
        );
      });

      it('flashes an error message', () => {
        actions.receiveRemoveStageError({ commit: () => {}, state }, {});
        shouldFlashAMessage('There was an error removing your custom stage, please try again');
      });
    });
  });

  describe('receiveRemoveStageSuccess', () => {
    const stageId = 'cool-stage';

    beforeEach(() => {
      mock.onDelete(stageEndpoint({ stageId })).replyOnce(200);
      state = { selectedGroup };
    });

    it('dispatches fetchCycleAnalyticsData', () => {
      return testAction(
        actions.receiveRemoveStageSuccess,
        stageId,
        state,
        [{ type: 'RECEIVE_REMOVE_STAGE_RESPONSE' }],
        [{ type: 'fetchCycleAnalyticsData' }],
      );
    });

    it('flashes a success message', () => {
      return actions
        .receiveRemoveStageSuccess(
          {
            dispatch: () => Promise.resolve(),
            commit: () => {},
            state,
          },
          {},
        )
        .then(() => shouldFlashAMessage('Stage removed', 'notice'));
    });
  });

  describe('fetchStageMedianValues', () => {
    let mockDispatch = jest.fn();
    beforeEach(() => {
      state = { ...state, stages: [{ slug: selectedStageSlug }], selectedGroup };
      mock = new MockAdapter(axios);
      mock.onGet(endpoints.stageMedian).reply(200, { events: [] });
      mockDispatch = jest.fn();
    });

    it('dispatches receiveStageMedianValuesSuccess with received data on success', () => {
      return actions
        .fetchStageMedianValues({
          state,
          getters,
          commit: () => {},
          dispatch: mockDispatch,
        })
        .then(() => {
          expect(mockDispatch).toHaveBeenCalledWith('requestStageMedianValues');
          expect(mockDispatch).toHaveBeenCalledWith('receiveStageMedianValuesSuccess', [
            { events: [], id: selectedStageSlug },
          ]);
        });
    });

    describe('with a failing request', () => {
      beforeEach(() => {
        mock.onGet(endpoints.stageMedian).reply(httpStatusCodes.NOT_FOUND, { error });
      });

      it('will dispatch receiveStageMedianValuesError', () => {
        return actions
          .fetchStageMedianValues({
            state,
            getters,
            commit: () => {},
            dispatch: mockDispatch,
          })
          .then(() => {
            expect(mockDispatch).toHaveBeenCalledWith('requestStageMedianValues');
            expect(mockDispatch).toHaveBeenCalledWith('receiveStageMedianValuesError', error);
          });
      });
    });
  });

  describe('receiveStageMedianValuesError', () => {
    beforeEach(() => {});

    it(`commits the ${types.RECEIVE_STAGE_MEDIANS_ERROR} mutation`, () => {
      testAction(
        actions.receiveStageMedianValuesError,
        null,
        state,
        [
          {
            type: types.RECEIVE_STAGE_MEDIANS_ERROR,
          },
        ],
        [],
      );
    });

    it('will flash an error message', () => {
      actions.receiveStageMedianValuesError({ commit: () => {} });
      shouldFlashAMessage('There was an error fetching median data for stages');
    });
  });

  describe('receiveStageMedianValuesSuccess', () => {
    it(`commits the ${types.RECEIVE_STAGE_MEDIANS_SUCCESS} mutation`, () => {
      return testAction(
        actions.receiveStageMedianValuesSuccess,
        { ...stageData },
        state,
        [{ type: types.RECEIVE_STAGE_MEDIANS_SUCCESS, payload: { events: [] } }],
        [],
      );
    });
  });

  describe('initializeCycleAnalytics', () => {
    let mockDispatch;
    let mockCommit;
    let store;

    const initialData = {
      group: selectedGroup,
      projectIds: [1, 2],
    };

    beforeEach(() => {
      mockDispatch = jest.fn(() => Promise.resolve());
      mockCommit = jest.fn();
      store = {
        state,
        getters,
        commit: mockCommit,
        dispatch: mockDispatch,
      };
    });

    describe('with no initialData', () => {
      it('commits "INITIALIZE_CYCLE_ANALYTICS"', () =>
        actions.initializeCycleAnalytics(store).then(() => {
          expect(mockCommit).toHaveBeenCalledWith('INITIALIZE_CYCLE_ANALYTICS', {});
        }));

      it('dispatches "initializeCycleAnalyticsSuccess"', () =>
        actions.initializeCycleAnalytics(store).then(() => {
          expect(mockDispatch).not.toHaveBeenCalledWith('fetchCycleAnalyticsData');
          expect(mockDispatch).toHaveBeenCalledWith('initializeCycleAnalyticsSuccess');
        }));
    });

    describe('with initialData', () => {
      it('dispatches "fetchCycleAnalyticsData" and "initializeCycleAnalyticsSuccess"', () =>
        actions.initializeCycleAnalytics(store, initialData).then(() => {
          expect(mockDispatch).toHaveBeenCalledWith('fetchCycleAnalyticsData');
          expect(mockDispatch).toHaveBeenCalledWith('initializeCycleAnalyticsSuccess');
        }));

      it('commits "INITIALIZE_CYCLE_ANALYTICS"', () =>
        actions.initializeCycleAnalytics(store, initialData).then(() => {
          expect(mockCommit).toHaveBeenCalledWith('INITIALIZE_CYCLE_ANALYTICS', initialData);
        }));
    });
  });

  describe('initializeCycleAnalyticsSuccess', () => {
    it(`commits the ${types.INITIALIZE_CYCLE_ANALYTICS_SUCCESS} mutation`, () =>
      testAction(
        actions.initializeCycleAnalyticsSuccess,
        null,
        state,
        [{ type: types.INITIALIZE_CYCLE_ANALYTICS_SUCCESS }],
        [],
      ));
  });

  describe('reorderStage', () => {
    const stageId = 'cool-stage';
    const payload = { id: stageId, move_after_id: '2', move_before_id: '8' };

    beforeEach(() => {
      state = { selectedGroup };
    });

    describe('with no errors', () => {
      beforeEach(() => {
        mock.onPut(stageEndpoint({ stageId })).replyOnce(httpStatusCodes.OK);
      });

      it(`dispatches the ${types.REQUEST_REORDER_STAGE} and ${types.RECEIVE_REORDER_STAGE_SUCCESS} actions`, () => {
        return testAction(
          actions.reorderStage,
          payload,
          state,
          [],
          [{ type: 'requestReorderStage' }, { type: 'receiveReorderStageSuccess' }],
        );
      });
    });

    describe('with errors', () => {
      beforeEach(() => {
        mock.onPut(stageEndpoint({ stageId })).replyOnce(httpStatusCodes.NOT_FOUND);
      });

      it(`dispatches the ${types.REQUEST_REORDER_STAGE} and ${types.RECEIVE_REORDER_STAGE_ERROR} actions `, () => {
        return testAction(
          actions.reorderStage,
          payload,
          state,
          [],
          [
            { type: 'requestReorderStage' },
            { type: 'receiveReorderStageError', payload: { status: httpStatusCodes.NOT_FOUND } },
          ],
        );
      });
    });
  });

  describe('receiveReorderStageError', () => {
    beforeEach(() => {});

    it(`commits the ${types.RECEIVE_REORDER_STAGE_ERROR} mutation and flashes an error`, () => {
      return testAction(
        actions.receiveReorderStageError,
        null,
        state,
        [
          {
            type: types.RECEIVE_REORDER_STAGE_ERROR,
          },
        ],
        [],
      ).then(() => {
        shouldFlashAMessage(
          'There was an error updating the stage order. Please try reloading the page.',
        );
      });
    });
  });

  describe('receiveReorderStageSuccess', () => {
    it(`commits the ${types.RECEIVE_REORDER_STAGE_SUCCESS} mutation`, () => {
      return testAction(
        actions.receiveReorderStageSuccess,
        null,
        state,
        [{ type: types.RECEIVE_REORDER_STAGE_SUCCESS }],
        [],
      );
    });
  });
});
