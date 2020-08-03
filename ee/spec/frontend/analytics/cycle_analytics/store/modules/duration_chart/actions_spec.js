import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as rootGetters from 'ee/analytics/cycle_analytics/store/getters';
import * as getters from 'ee/analytics/cycle_analytics/store/modules/duration_chart/getters';
import * as actions from 'ee/analytics/cycle_analytics/store/modules/duration_chart/actions';
import * as types from 'ee/analytics/cycle_analytics/store/modules/duration_chart/mutation_types';
import {
  group,
  allowedStages as stages,
  startDate,
  endDate,
  rawDurationData,
  rawDurationMedianData,
  transformedDurationData,
  transformedDurationMedianData,
  endpoints,
  valueStreams,
} from '../../../mock_data';
import { shouldFlashAMessage } from '../../../helpers';

const selectedGroup = { fullPath: group.path };
const [stage1, stage2] = stages;
const hiddenStage = { ...stage1, hidden: true, id: 3, slug: 3 };
const activeStages = [stage1, stage2];
const [selectedValueStream] = valueStreams;

const rootState = {
  startDate,
  endDate,
  stages: [...activeStages, hiddenStage],
  selectedGroup,
  selectedValueStream,
  featureFlags: {
    hasDurationChart: true,
    hasDurationChartMedian: true,
  },
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

  describe('fetchDurationData', () => {
    beforeEach(() => {
      mock.onGet(endpoints.durationData).reply(200, [...rawDurationData]);
    });

    it("dispatches the 'requestDurationData' and 'receiveDurationDataSuccess' actions on success", () => {
      return testAction(
        actions.fetchDurationData,
        null,
        state,
        [],
        [
          { type: 'requestDurationData' },
          {
            type: 'receiveDurationDataSuccess',
            payload: transformedDurationData,
          },
        ],
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

    describe('receiveDurationDataError', () => {
      beforeEach(() => {
        mock.onGet(endpoints.durationData).reply(404);
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
            expect(dispatch).toHaveBeenCalledWith('receiveDurationDataError');
          });
      });
    });
  });

  describe('receiveDurationDataSuccess', () => {
    describe('with hasDurationChartMedian feature flag enabled', () => {
      it('commits the transformed duration data and dispatches fetchDurationMedianData', () => {
        testAction(
          actions.receiveDurationDataSuccess,
          transformedDurationData,
          rootState,
          [
            {
              type: types.RECEIVE_DURATION_DATA_SUCCESS,
              payload: transformedDurationData,
            },
          ],
          [
            {
              type: 'fetchDurationMedianData',
            },
          ],
        );
      });
    });

    describe('with hasDurationChartMedian feature flag disabled', () => {
      const disabledState = {
        ...rootState,
        featureFlags: {
          hasDurationChartMedian: false,
        },
      };

      it('commits the transformed duration data', () => {
        testAction(
          actions.receiveDurationDataSuccess,
          transformedDurationData,
          disabledState,
          [
            {
              type: types.RECEIVE_DURATION_DATA_SUCCESS,
              payload: transformedDurationData,
            },
          ],
          [],
        );
      });
    });
  });

  describe('receiveDurationDataError', () => {
    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
    });

    it("commits the 'RECEIVE_DURATION_DATA_ERROR' mutation", () => {
      testAction(
        actions.receiveDurationDataError,
        {},
        rootState,
        [
          {
            type: types.RECEIVE_DURATION_DATA_ERROR,
          },
        ],
        [],
      );
    });

    it('will flash an error', () => {
      actions.receiveDurationDataError({
        commit: () => {},
      });

      shouldFlashAMessage(
        'There was an error while fetching value stream analytics duration data.',
      );
    });
  });

  describe('updateSelectedDurationChartStages', () => {
    it("commits the 'UPDATE_SELECTED_DURATION_CHART_STAGES' mutation with all the selected stages in the duration data", () => {
      const stateWithDurationData = {
        ...state,
        durationData: transformedDurationData,
        durationMedianData: transformedDurationMedianData,
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
              updatedDurationStageMedianData: transformedDurationMedianData,
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
        durationMedianData: transformedDurationMedianData,
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
              updatedDurationStageMedianData: [
                transformedDurationMedianData[0],
                {
                  ...transformedDurationMedianData[1],
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
        durationMedianData: transformedDurationMedianData,
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
              updatedDurationStageMedianData: [
                {
                  ...transformedDurationMedianData[0],
                  selected: false,
                },
                {
                  ...transformedDurationMedianData[1],
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

  describe('fetchDurationMedianData', () => {
    beforeEach(() => {
      mock.onGet(endpoints.durationData).reply(200, [...rawDurationMedianData]);
    });

    it('dispatches the receiveDurationMedianDataSuccess action on success', () => {
      return testAction(
        actions.fetchDurationMedianData,
        null,
        state,
        [],
        [
          {
            type: 'receiveDurationMedianDataSuccess',
            payload: transformedDurationMedianData,
          },
        ],
      );
    });

    describe('receiveDurationMedianDataError', () => {
      beforeEach(() => {
        mock.onGet(endpoints.durationData).reply(404);
      });

      it('dispatches the receiveDurationMedianDataError action when there is an error', () => {
        const dispatch = jest.fn();
        return actions
          .fetchDurationMedianData({
            dispatch,
            rootState,
            rootGetters: { ...rootGetters, activeStages },
          })
          .then(() => {
            const requestedUrls = mock.history.get.map(({ url }) => url);
            expect(requestedUrls).not.toContain(
              `/groups/foo/-/analytics/value_stream_analytics/stages/${hiddenStage.id}/duration_chart`,
            );
            expect(dispatch).toHaveBeenCalledWith('receiveDurationMedianDataError');
          });
      });
    });
  });

  describe('receiveDurationMedianDataSuccess', () => {
    it('commits the transformed duration median data', () => {
      return testAction(
        actions.receiveDurationMedianDataSuccess,
        transformedDurationMedianData,
        rootState,
        [
          {
            type: types.RECEIVE_DURATION_MEDIAN_DATA_SUCCESS,
            payload: transformedDurationMedianData,
          },
        ],
        [],
      );
    });
  });

  describe('receiveDurationMedianDataError', () => {
    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
    });

    it("commits the 'RECEIVE_DURATION_MEDIAN_DATA_ERROR' mutation", () => {
      return testAction(
        actions.receiveDurationMedianDataError,
        {},
        rootState,
        [
          {
            type: types.RECEIVE_DURATION_MEDIAN_DATA_ERROR,
          },
        ],
        [],
      );
    });

    it('will flash an error', () => {
      actions.receiveDurationMedianDataError({
        commit: () => {},
      });

      shouldFlashAMessage(
        'There was an error while fetching value stream analytics duration median data.',
      );
    });
  });
});
