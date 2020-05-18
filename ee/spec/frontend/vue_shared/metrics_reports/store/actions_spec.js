import MockAdapter from 'axios-mock-adapter';
import {
  setEndpoint,
  requestMetrics,
  fetchMetrics,
  receiveMetricsSuccess,
  receiveMetricsError,
} from 'ee/vue_shared/metrics_reports/store/actions';
import * as types from 'ee/vue_shared/metrics_reports/store/mutation_types';
import state from 'ee/vue_shared/metrics_reports/store/state';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';

describe('metrics reports actions', () => {
  let mockedState;
  let mock;

  beforeEach(() => {
    mockedState = state();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setEndpoint', () => {
    it('should commit set endpoint', () => {
      return testAction(
        setEndpoint,
        'path',
        mockedState,
        [
          {
            type: types.SET_ENDPOINT,
            payload: 'path',
          },
        ],
        [],
      );
    });
  });

  describe('requestMetrics', () => {
    it('should commit request mutation', () => {
      return testAction(
        requestMetrics,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_METRICS,
          },
        ],
        [],
      );
    });
  });

  describe('fetchMetrics', () => {
    it('should call metrics endpoint', () => {
      const data = {
        metrics: [
          {
            name: 'name',
            value: 'value',
          },
        ],
      };
      const endpoint = '/mock-endpoint.json';
      mockedState.endpoint = endpoint;
      mock.onGet(endpoint).replyOnce(200, data);

      return testAction(
        fetchMetrics,
        null,
        mockedState,
        [],
        [
          {
            type: 'requestMetrics',
          },
          {
            payload: data,
            type: 'receiveMetricsSuccess',
          },
        ],
      );
    });

    it('handles errors', () => {
      const endpoint = '/mock-endpoint.json';
      mockedState.endpoint = endpoint;
      mock.onGet(endpoint).replyOnce(500);

      return testAction(
        fetchMetrics,
        null,
        mockedState,
        [],
        [
          {
            type: 'requestMetrics',
          },
          {
            type: 'receiveMetricsError',
          },
        ],
      );
    });
  });

  describe('receiveMetricsSuccess', () => {
    it('should commit request mutation', () => {
      const response = { metrics: [] };
      return testAction(
        receiveMetricsSuccess,
        response,
        mockedState,
        [
          {
            type: types.RECEIVE_METRICS_SUCCESS,
            payload: response,
          },
        ],
        [],
      );
    });
  });

  describe('receiveMetricsError', () => {
    it('should commit request mutation', () => {
      return testAction(
        receiveMetricsError,
        null,
        mockedState,
        [
          {
            type: types.RECEIVE_METRICS_ERROR,
          },
        ],
        [],
      );
    });
  });
});
