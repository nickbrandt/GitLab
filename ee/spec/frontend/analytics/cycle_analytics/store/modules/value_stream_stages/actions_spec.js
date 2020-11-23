import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import * as rootGetters from 'ee/analytics/cycle_analytics/store/getters';
import * as actions from 'ee/analytics/cycle_analytics/store/modules/value_stream_stages/actions';
import * as types from 'ee/analytics/cycle_analytics/store/modules/value_stream_stages/mutation_types';
import testAction from 'helpers/vuex_action_helper';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import httpStatusCodes from '~/lib/utils/http_status';
import {
  currentGroup,
  allowedStages as stages,
  startDate,
  endDate,
  valueStreams,
  endpoints,
} from '../../../mock_data';

const stageData = { events: [] };
const error = new Error(`Request failed with status code ${httpStatusCodes.NOT_FOUND}`);
const flashErrorMessage = 'There was an error while fetching value stream analytics data.';

stages[0].hidden = true;
const activeStages = stages.filter(({ hidden }) => !hidden);
const hiddenStage = stages[0];

const [selectedStage] = activeStages;
const selectedStageSlug = selectedStage.slug;
const [selectedValueStream] = valueStreams;

const mockGetters = {
  currentGroupPath: () => currentGroup.fullPath,
  currentValueStreamId: () => selectedValueStream.id,
};

const stageEndpoint = ({ stageId }) =>
  `/groups/${currentGroup.fullPath}/-/analytics/value_stream_analytics/value_streams/${selectedValueStream.id}/stages/${stageId}`;

jest.mock('~/flash');

describe('Value Stream Analytics stages actions', () => {
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
      },
      selectedValueStream,
      activeStages,
      ...mockGetters,
    };
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    state = { ...state, currentGroup: null };
  });

  it.each`
    action                | type                    | stateKey           | payload
    ${'setSelectedStage'} | ${'SET_SELECTED_STAGE'} | ${'selectedStage'} | ${{ id: 'someStageId' }}
  `('$action should set $stateKey with $payload and type $type', ({ action, type, payload }) => {
    return testAction(
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

  describe('setDefaultSelectedStage', () => {
    it("dispatches the 'fetchStageData' action", () => {
      return testAction(
        actions.setDefaultSelectedStage,
        null,
        state,
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
      actions.setDefaultSelectedStage(
        { rootGetters: { activeStages: data }, dispatch: () => {} },
        {},
      );
      shouldFlashAMessage(flashErrorMessage);
    });

    it('will select the first active stage', () => {
      return testAction(
        actions.setDefaultSelectedStage,
        null,
        state,
        [],
        [
          { type: 'setSelectedStage', payload: stages[1] },
          { type: 'fetchStageData', payload: stages[1].slug },
        ],
      );
    });
  });

  describe('fetchStageMedianValues', () => {
    let mockDispatch = jest.fn();
    const fetchMedianResponse = activeStages.map(({ slug: id }) => ({ events: [], id }));

    beforeEach(() => {
      state = { ...state, stages, ...mockGetters };
      mock = new MockAdapter(axios);
      mock.onGet(endpoints.stageMedian).reply(httpStatusCodes.OK, { events: [] });
      mockDispatch = jest.fn();
    });

    it('dispatches receiveStageMedianValuesSuccess with received data on success', () => {
      return testAction(
        actions.fetchStageMedianValues,
        null,
        state,
        [{ type: types.RECEIVE_STAGE_MEDIANS_SUCCESS, payload: fetchMedianResponse }],
        [{ type: 'requestStageMedianValues' }],
      );
    });

    it('does not request hidden stages', () => {
      return actions
        .fetchStageMedianValues({
          state,
          rootGetters: {
            ...rootGetters,
            activeStages,
          },
          commit: () => {},
          dispatch: mockDispatch,
        })
        .then(() => {
          expect(mockDispatch).not.toHaveBeenCalledWith('receiveStageMedianValuesSuccess', {
            events: [],
            id: hiddenStage.id,
          });
        });
    });

    describe(`Status ${httpStatusCodes.OK} and error message in response`, () => {
      const dataError = 'Too much data';
      const payload = activeStages.map(({ slug: id }) => ({ value: null, id, error: dataError }));

      beforeEach(() => {
        mock.onGet(endpoints.stageMedian).reply(httpStatusCodes.OK, { error: dataError });
      });

      it(`dispatches the 'RECEIVE_STAGE_MEDIANS_SUCCESS' with ${dataError}`, () => {
        return testAction(
          actions.fetchStageMedianValues,
          null,
          state,
          [{ type: types.RECEIVE_STAGE_MEDIANS_SUCCESS, payload }],
          [{ type: 'requestStageMedianValues' }],
        );
      });
    });

    describe('with a failing request', () => {
      beforeEach(() => {
        mock.onGet(endpoints.stageMedian).reply(httpStatusCodes.NOT_FOUND, { error });
      });

      it('will dispatch receiveStageMedianValuesError', () => {
        return testAction(
          actions.fetchStageMedianValues,
          null,
          state,
          [],
          [
            { type: 'requestStageMedianValues' },
            { type: 'receiveStageMedianValuesError', payload: error },
          ],
        );
      });
    });
  });

  describe('receiveStageMedianValuesError', () => {
    it(`commits the ${types.RECEIVE_STAGE_MEDIANS_ERROR} mutation`, () =>
      testAction(
        actions.receiveStageMedianValuesError,
        {},
        state,
        [
          {
            type: types.RECEIVE_STAGE_MEDIANS_ERROR,
            payload: {},
          },
        ],
        [],
      ));

    it('will flash an error message', () => {
      actions.receiveStageMedianValuesError({ commit: () => {} });
      shouldFlashAMessage('There was an error fetching median data for stages');
    });
  });

  describe('fetchStageData', () => {
    beforeEach(() => {
      state = { ...state, currentGroup };
      mock = new MockAdapter(axios);
      mock.onGet(endpoints.stageData).reply(httpStatusCodes.OK, { events: [] });
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
    const message = 'fake error';

    it(`commits the ${types.RECEIVE_STAGE_DATA_ERROR} mutation`, () => {
      return testAction(
        actions.receiveStageDataError,
        { message },
        state,
        [
          {
            type: types.RECEIVE_STAGE_DATA_ERROR,
            payload: message,
          },
        ],
        [],
      );
    });

    it('will flash an error message', () => {
      actions.receiveStageDataError({ commit: () => {} }, {});
      shouldFlashAMessage('There was an error fetching data for the selected stage');
    });
  });

  describe('reorderStage', () => {
    const stageId = 'cool-stage';
    const payload = { id: stageId, move_after_id: '2', move_before_id: '8' };

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

  describe('updateStage', () => {
    const stageId = 'cool-stage';
    const payload = { hidden: true };

    beforeEach(() => {
      mock.onPut(stageEndpoint({ stageId }), payload).replyOnce(httpStatusCodes.OK, payload);
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
          { type: 'customStages/setSavingCustomStage', payload: null },
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
            { type: 'customStages/setSavingCustomStage', payload: null },
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
            { type: 'fetchGroupStagesAndEvents', payload: null },
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
      mock.onDelete(stageEndpoint({ stageId })).replyOnce(httpStatusCodes.OK);
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
      mock.onDelete(stageEndpoint({ stageId })).replyOnce(httpStatusCodes.OK);
      state = { currentGroup };
    });

    it('dispatches fetchCycleAnalyticsData', () => {
      return testAction(
        actions.receiveRemoveStageSuccess,
        stageId,
        state,
        [{ type: 'RECEIVE_REMOVE_STAGE_RESPONSE' }],
        [{ type: 'fetchCycleAnalyticsData', payload: null }],
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
});
