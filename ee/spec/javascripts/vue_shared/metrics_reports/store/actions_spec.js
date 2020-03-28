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
import testAction from 'spec/helpers/vuex_action_helper';
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
    it('should commit set endpoint', done => {
      testAction(
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
        done,
      );
    });
  });

  describe('requestMetrics', () => {
    it('should commit request mutation', done => {
      testAction(
        requestMetrics,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_METRICS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchMetrics', () => {
    it('should call metrics endpoint', done => {
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

      testAction(
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
        done,
      );
    });

    it('handles errors', done => {
      const endpoint = '/mock-endpoint.json';
      mockedState.endpoint = endpoint;
      mock.onGet(endpoint).replyOnce(500);

      testAction(
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
        done,
      );
    });
  });

  describe('receiveMetricsSuccess', () => {
    it('should commit request mutation', done => {
      const response = { metrics: [] };
      testAction(
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
        done,
      );
    });
  });

  describe('receiveMetricsError', () => {
    it('should commit request mutation', done => {
      testAction(
        receiveMetricsError,
        null,
        mockedState,
        [
          {
            type: types.RECEIVE_METRICS_ERROR,
          },
        ],
        [],
        done,
      );
    });
  });
});
