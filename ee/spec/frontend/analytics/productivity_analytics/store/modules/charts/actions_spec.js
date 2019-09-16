import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'helpers/test_constants';
import * as actions from 'ee/analytics/productivity_analytics/store/modules/charts/actions';
import * as types from 'ee/analytics/productivity_analytics/store/modules/charts/mutation_types';
import getInitialState from 'ee/analytics/productivity_analytics/store/modules/charts/state';
import { chartKeys } from 'ee/analytics/productivity_analytics/constants';
import { mockHistogramData } from '../../../mock_data';

describe('Productivity analytics chart actions', () => {
  let mockedContext;
  let mockedState;
  let mock;

  const chartKey = 'main';
  const globalParams = {
    group_id: 'gitlab-org',
    project_id: 'gitlab-org/gitlab-test',
  };

  beforeEach(() => {
    mockedContext = {
      dispatch() {},
      rootState: {
        endpoint: `${TEST_HOST}/analytics/productivity_analytics.json`,
      },
      getters: {
        getFilterParams: () => globalParams,
      },
      state: getInitialState(),
    };

    // testAction looks for rootGetters in state,
    // so they need to be concatenated here.
    mockedState = {
      ...mockedContext.state,
      ...mockedContext.getters,
      ...mockedContext.rootState,
    };

    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('fetchChartData', () => {
    describe('success', () => {
      beforeEach(() => {
        mock.onGet(mockedState.endpoint).replyOnce(200, mockHistogramData);
      });

      it('calls API with params', () => {
        jest.spyOn(axios, 'get');

        actions.fetchChartData(mockedContext, chartKey);

        expect(axios.get).toHaveBeenCalledWith(mockedState.endpoint, { params: globalParams });
      });

      it('dispatches success with received data', done =>
        testAction(
          actions.fetchChartData,
          chartKey,
          mockedState,
          [],
          [
            { type: 'requestChartData', payload: chartKey },
            {
              type: 'receiveChartDataSuccess',
              payload: expect.objectContaining({ chartKey, data: mockHistogramData }),
            },
          ],
          done,
        ));
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(mockedState.endpoint).replyOnce(500, chartKey);
      });

      it('dispatches error', done => {
        testAction(
          actions.fetchChartData,
          chartKey,
          mockedState,
          [],
          [
            {
              type: 'requestChartData',
              payload: chartKey,
            },
            {
              type: 'receiveChartDataError',
              payload: chartKey,
            },
          ],
          done,
        );
      });
    });
  });

  describe('requestChartData', () => {
    it('should commit the request mutation', done => {
      testAction(
        actions.requestChartData,
        chartKey,
        mockedContext.state,
        [{ type: types.REQUEST_CHART_DATA, payload: chartKey }],
        [],
        done,
      );
    });
  });

  describe('receiveChartDataSuccess', () => {
    it('should commit received data', done => {
      testAction(
        actions.receiveChartDataSuccess,
        { chartKey, data: mockHistogramData },
        mockedContext.state,
        [
          {
            type: types.RECEIVE_CHART_DATA_SUCCESS,
            payload: { chartKey, data: mockHistogramData },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveChartDataError', () => {
    it('should commit error', done => {
      testAction(
        actions.receiveChartDataError,
        chartKey,
        mockedContext.state,
        [
          {
            type: types.RECEIVE_CHART_DATA_ERROR,
            payload: chartKey,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchAllChartData', () => {
    it('commits reset for the main chart and dispatches fetchChartData for all chart types', done => {
      testAction(
        actions.fetchAllChartData,
        null,
        mockedContext.state,
        [{ type: types.RESET_CHART_DATA, payload: chartKeys.main }],
        [
          { type: 'fetchChartData', payload: chartKeys.main },
          { type: 'fetchChartData', payload: chartKeys.timeBasedHistogram },
          { type: 'fetchChartData', payload: chartKeys.commitBasedHistogram },
          { type: 'fetchChartData', payload: chartKeys.scatterplot },
        ],
        done,
      );
    });
  });

  describe('setMetricType', () => {
    const metricType = 'time_to_merge';

    it('should commit metricType', done => {
      testAction(
        actions.setMetricType,
        { chartKey, metricType },
        mockedContext.state,
        [{ type: types.SET_METRIC_TYPE, payload: { chartKey, metricType } }],
        [{ type: 'fetchChartData', payload: chartKey }],
        done,
      );
    });
  });

  describe('chartItemClicked', () => {
    const item = 5;
    it('should commit selected chart item', done => {
      testAction(
        actions.chartItemClicked,
        { chartKey, item },
        mockedContext.state,
        [{ type: types.UPDATE_SELECTED_CHART_ITEMS, payload: { chartKey, item } }],
        [
          { type: 'fetchChartData', payload: chartKeys.timeBasedHistogram },
          { type: 'fetchChartData', payload: chartKeys.commitBasedHistogram },
          { type: 'table/fetchMergeRequests', payload: null },
        ],
        done,
      );
    });
  });
});
