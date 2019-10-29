import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';

import testAction from 'helpers/vuex_action_helper';
import * as types from 'ee/logs/stores/mutation_types';
import logsPageState from 'ee/logs/stores/state';
import { setLogsEndpoint, fetchEnvironments, fetchLogs } from 'ee/logs/stores/actions';

import flash from '~/flash';

import {
  mockLogsEndpoint,
  mockEnvironments,
  mockPods,
  mockPodName,
  mockLines,
  mockEnvironmentsEndpoint,
} from '../mock_data';

jest.mock('~/flash');

describe('Logs Store actions', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = logsPageState();
  });

  afterEach(() => {
    flash.mockClear();
  });

  describe('setLogsEndpoint', () => {
    it('should commit SET_LOGS_ENDPOINT mutation', done => {
      testAction(
        setLogsEndpoint,
        mockLogsEndpoint,
        state,
        [{ type: types.SET_LOGS_ENDPOINT, payload: mockLogsEndpoint }],
        [],
        done,
      );
    });
  });

  describe('fetchEnvironments', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    it('should commit RECEIVE_ENVIRONMENTS_DATA_SUCCESS mutation on correct data', done => {
      mock.onGet(mockEnvironmentsEndpoint).replyOnce(200, { environments: mockEnvironments });
      testAction(
        fetchEnvironments,
        mockEnvironmentsEndpoint,
        state,
        [
          { type: types.REQUEST_ENVIRONMENTS_DATA },
          { type: types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS, payload: mockEnvironments },
        ],
        [],
        done,
      );
    });

    it('should commit RECEIVE_ENVIRONMENTS_DATA_ERROR on wrong data', done => {
      mock.onGet(mockEnvironmentsEndpoint).replyOnce(500);
      testAction(
        fetchEnvironments,
        mockEnvironmentsEndpoint,
        state,
        [
          { type: types.REQUEST_ENVIRONMENTS_DATA },
          { type: types.RECEIVE_ENVIRONMENTS_DATA_ERROR },
        ],
        [],
        () => {
          expect(flash).toHaveBeenCalledTimes(1);
          done();
        },
      );
    });

    it('should commit RECEIVE_ENVIRONMENTS_DATA_ERROR on error', done => {
      mock.onGet('/root/autodevops-deploy/environments.json').replyOnce(500);
      testAction(
        fetchEnvironments,
        '/root/autodevops-deploy/environments.json',
        state,
        [
          { type: types.REQUEST_ENVIRONMENTS_DATA },
          { type: types.RECEIVE_ENVIRONMENTS_DATA_ERROR },
        ],
        [],
        () => {
          expect(flash).toHaveBeenCalledTimes(1);
          done();
        },
      );
    });
  });

  describe('fetchLogs', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    it('should commit logs and pod data when there is pod name defined', done => {
      state.logs.endpoint = mockLogsEndpoint;

      mock.onGet(mockLogsEndpoint).replyOnce(200, {
        pods: mockPods,
        logs: mockLines,
      });

      testAction(
        fetchLogs,
        mockPodName,
        state,
        [
          { type: types.SET_CURRENT_POD_NAME, payload: mockPodName },
          { type: types.REQUEST_PODS_DATA },
          { type: types.REQUEST_LOGS_DATA },
          { type: types.RECEIVE_PODS_DATA_SUCCESS, payload: mockPods },
          { type: types.RECEIVE_LOGS_DATA_SUCCESS, payload: mockLines },
        ],
        [],
        done,
      );
    });

    it('should commit logs and pod data when no pod name defined', done => {
      state.logs.endpoint = mockLogsEndpoint;

      mock.onGet(mockLogsEndpoint).replyOnce(200, {
        pods: mockPods,
        logs: mockLines,
      });

      testAction(
        fetchLogs,
        null,
        state,
        [
          { type: types.REQUEST_PODS_DATA },
          { type: types.REQUEST_LOGS_DATA },
          { type: types.SET_CURRENT_POD_NAME, payload: mockPods[0] },
          { type: types.RECEIVE_PODS_DATA_SUCCESS, payload: mockPods },
          { type: types.RECEIVE_LOGS_DATA_SUCCESS, payload: mockLines },
        ],
        [],
        done,
      );
    });

    it('should commit logs and pod errors', done => {
      state.logs.endpoint = mockLogsEndpoint;

      mock.onGet(mockLogsEndpoint).replyOnce(500);

      testAction(
        fetchLogs,
        mockPodName,
        state,
        [
          { type: types.SET_CURRENT_POD_NAME, payload: mockPodName },
          { type: types.REQUEST_PODS_DATA },
          { type: types.REQUEST_LOGS_DATA },
          { type: types.RECEIVE_PODS_DATA_ERROR },
          { type: types.RECEIVE_LOGS_DATA_ERROR },
        ],
        [],
        () => {
          expect(flash).toHaveBeenCalledTimes(1);
          done();
        },
      );
    });
  });
});
