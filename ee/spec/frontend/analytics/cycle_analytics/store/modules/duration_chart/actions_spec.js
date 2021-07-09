import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import * as rootGetters from 'ee/analytics/cycle_analytics/store/getters';
import * as actions from 'ee/analytics/cycle_analytics/store/modules/duration_chart/actions';
import * as getters from 'ee/analytics/cycle_analytics/store/modules/duration_chart/getters';
import * as types from 'ee/analytics/cycle_analytics/store/modules/duration_chart/mutation_types';
import testAction from 'helpers/vuex_action_helper';
import { createdAfter, createdBefore, group } from 'jest/cycle_analytics/mock_data';
import createFlash from '~/flash';
import httpStatusCodes from '~/lib/utils/http_status';
import {
  allowedStages as stages,
  rawDurationData,
  transformedDurationData,
  endpoints,
  valueStreams,
} from '../../../mock_data';

jest.mock('~/flash');
const selectedGroup = { fullPath: group.path };
const [stage1, stage2] = stages;
const hiddenStage = { ...stage1, hidden: true, id: 3, slug: 3 };
const activeStages = [stage1, stage2];
const [selectedValueStream] = valueStreams;
const error = new Error(`Request failed with status code ${httpStatusCodes.BAD_REQUEST}`);

const rootState = {
  createdAfter,
  createdBefore,
  stages: [...activeStages, hiddenStage],
  selectedGroup,
  selectedValueStream,
  featureFlags: {},
};

describe('DurationChart actions', () => {
  let mock;
  const state = {
    ...rootState,
    ...getters,
    ...rootGetters,
    activeStages,
    currentGroupPath: () => selectedGroup.fullPath,
    currentValueStreamId: () => selectedValueStream.id,
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setLoading', () => {
    it(`commits the '${types.SET_LOADING}' action`, () => {
      return testAction(
        actions.setLoading,
        true,
        state,
        [{ type: types.SET_LOADING, payload: true }],
        [],
      );
    });
  });

  describe('fetchDurationData', () => {
    beforeEach(() => {
      mock.onGet(endpoints.durationData).reply(200, [...rawDurationData]);
    });

    it("dispatches the 'requestDurationData' and 'receiveDurationDataSuccess' actions on success", () => {
      return testAction(
        actions.fetchDurationData,
        null,
        state,
        [
          {
            type: types.RECEIVE_DURATION_DATA_SUCCESS,
            payload: transformedDurationData,
          },
        ],
        [{ type: 'requestDurationData' }],
      );
    });

    it('does not request hidden stages', () => {
      const dispatch = jest.fn();
      return actions
        .fetchDurationData({
          dispatch,
          rootState,
          rootGetters: {
            ...rootGetters,
            activeStages,
          },
        })
        .then(() => {
          const requestedUrls = mock.history.get.map(({ url }) => url);
          expect(requestedUrls).not.toContain(
            `/groups/foo/-/analytics/value_stream_analytics/stages/${hiddenStage.id}/duration_chart`,
          );
        });
    });

    describe(`Status ${httpStatusCodes.OK} and error message in response`, () => {
      const dataError = 'Too much data';

      beforeEach(() => {
        mock.onGet(endpoints.durationData).reply(httpStatusCodes.OK, { error: dataError });
      });

      it(`dispatches the 'receiveDurationDataError' with ${dataError}`, () => {
        const dispatch = jest.fn();
        const commit = jest.fn();

        return actions
          .fetchDurationData({
            dispatch,
            commit,
            rootState,
            rootGetters: {
              ...rootGetters,
              activeStages,
            },
          })
          .then(() => {
            expect(commit).not.toHaveBeenCalled();
            expect(dispatch.mock.calls).toEqual([
              ['requestDurationData'],
              ['receiveDurationDataError', new Error(dataError)],
            ]);
          });
      });
    });

    describe('receiveDurationDataError', () => {
      beforeEach(() => {
        mock.onGet(endpoints.durationData).reply(httpStatusCodes.BAD_REQUEST, error);
      });

      it("dispatches the 'receiveDurationDataError' action when there is an error", () => {
        const dispatch = jest.fn();

        return actions
          .fetchDurationData({
            dispatch,
            rootState,
            rootGetters: {
              ...rootGetters,
              activeStages,
            },
          })
          .then(() => {
            expect(dispatch.mock.calls).toEqual([
              ['requestDurationData'],
              ['receiveDurationDataError', error],
            ]);
          });
      });
    });
  });

  describe('receiveDurationDataError', () => {
    it("commits the 'RECEIVE_DURATION_DATA_ERROR' mutation", () => {
      testAction(
        actions.receiveDurationDataError,
        {},
        rootState,
        [
          {
            type: types.RECEIVE_DURATION_DATA_ERROR,
            payload: {},
          },
        ],
        [],
      );
    });

    it('will flash an error', () => {
      actions.receiveDurationDataError({
        commit: () => {},
      });

      expect(createFlash).toHaveBeenCalledWith({
        message: 'There was an error while fetching value stream analytics duration data.',
      });
    });
  });

  describe('updateSelectedDurationChartStages', () => {
    it("commits the 'UPDATE_SELECTED_DURATION_CHART_STAGES' mutation with all the selected stages in the duration data", () => {
      const stateWithDurationData = {
        ...state,
        durationData: transformedDurationData,
      };

      testAction(
        actions.updateSelectedDurationChartStages,
        [...stages],
        stateWithDurationData,
        [
          {
            type: types.UPDATE_SELECTED_DURATION_CHART_STAGES,
            payload: {
              updatedDurationStageData: transformedDurationData,
            },
          },
        ],
        [],
      );
    });

    it("commits the 'UPDATE_SELECTED_DURATION_CHART_STAGES' mutation with all the selected and deselected stages in the duration data", () => {
      const stateWithDurationData = {
        ...state,
        durationData: transformedDurationData,
      };

      testAction(
        actions.updateSelectedDurationChartStages,
        [stages[0]],
        stateWithDurationData,
        [
          {
            type: types.UPDATE_SELECTED_DURATION_CHART_STAGES,
            payload: {
              updatedDurationStageData: [
                transformedDurationData[0],
                {
                  ...transformedDurationData[1],
                  selected: false,
                },
              ],
            },
          },
        ],
        [],
      );
    });

    it("commits the 'UPDATE_SELECTED_DURATION_CHART_STAGES' mutation with all deselected stages in the duration data", () => {
      const stateWithDurationData = {
        ...state,
        durationData: transformedDurationData,
      };

      testAction(
        actions.updateSelectedDurationChartStages,
        [],
        stateWithDurationData,
        [
          {
            type: types.UPDATE_SELECTED_DURATION_CHART_STAGES,
            payload: {
              updatedDurationStageData: [
                {
                  ...transformedDurationData[0],
                  selected: false,
                },
                {
                  ...transformedDurationData[1],
                  selected: false,
                },
              ],
            },
          },
        ],
        [],
      );
    });
  });
});
