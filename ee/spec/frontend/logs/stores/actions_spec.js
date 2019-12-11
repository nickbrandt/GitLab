import MockAdapter from 'axios-mock-adapter';

import testAction from 'helpers/vuex_action_helper';
import * as types from 'ee/logs/stores/mutation_types';
import logsPageState from 'ee/logs/stores/state';
import { setInitData, showPodLogs, fetchEnvironments, fetchLogs } from 'ee/logs/stores/actions';
import axios from '~/lib/utils/axios_utils';

import flash from '~/flash';

import {
  mockProjectPath,
  mockPodName,
  mockEnvironmentsEndpoint,
  mockEnvironments,
  mockPods,
  mockLines,
  mockEnvName,
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

  describe('setInitData', () => {
    it('should commit environment and pod name mutation', done => {
      testAction(
        setInitData,
        { projectPath: mockProjectPath, environmentName: mockEnvName, podName: mockPodName },
        state,
        [
          { type: types.SET_PROJECT_PATH, payload: mockProjectPath },
          { type: types.SET_PROJECT_ENVIRONMENT, payload: mockEnvName },
          { type: types.SET_CURRENT_POD_NAME, payload: mockPodName },
        ],
        [{ type: 'fetchLogs' }],
        done,
      );
    });
  });

  describe('showPodLogs', () => {
    it('should commit pod name', done => {
      testAction(
        showPodLogs,
        mockPodName,
        state,
        [{ type: types.SET_CURRENT_POD_NAME, payload: mockPodName }],
        [{ type: 'fetchLogs' }],
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
  });

  describe('fetchLogs', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.reset();
    });

    it('should commit logs and pod data when there is pod name defined', done => {
      state.projectPath = mockProjectPath;
      state.environments.current = mockEnvName;
      state.pods.current = mockPodName;

      const endpoint = `/${mockProjectPath}/-/logs/k8s.json`;

      mock
        .onGet(endpoint, { params: { environment_name: mockEnvName, pod_name: mockPodName } })
        .reply(200, {
          pod_name: mockPodName,
          pods: mockPods,
          logs: mockLines,
        });

      mock.onGet(endpoint).replyOnce(202); // mock reactive cache

      testAction(
        fetchLogs,
        null,
        state,
        [
          { type: types.REQUEST_PODS_DATA },
          { type: types.REQUEST_LOGS_DATA },
          { type: types.SET_CURRENT_POD_NAME, payload: mockPodName },
          { type: types.RECEIVE_PODS_DATA_SUCCESS, payload: mockPods },
          { type: types.RECEIVE_LOGS_DATA_SUCCESS, payload: mockLines },
        ],
        [],
        done,
      );
    });

    it('should commit logs and pod data when no pod name defined', done => {
      state.projectPath = mockProjectPath;
      state.environments.current = mockEnvName;

      const endpoint = `/${mockProjectPath}/-/logs/k8s.json`;

      mock.onGet(endpoint, { params: { environment_name: mockEnvName } }).reply(200, {
        pod_name: mockPodName,
        pods: mockPods,
        logs: mockLines,
      });
      mock.onGet(endpoint).replyOnce(202); // mock reactive cache

      testAction(
        fetchLogs,
        null,
        state,
        [
          { type: types.REQUEST_PODS_DATA },
          { type: types.REQUEST_LOGS_DATA },
          { type: types.SET_CURRENT_POD_NAME, payload: mockPodName },
          { type: types.RECEIVE_PODS_DATA_SUCCESS, payload: mockPods },
          { type: types.RECEIVE_LOGS_DATA_SUCCESS, payload: mockLines },
        ],
        [],
        done,
      );
    });

    it('should commit logs and pod errors when backend fails', done => {
      state.projectPath = mockProjectPath;
      state.environments.current = mockEnvName;

      const endpoint = `/${mockProjectPath}/logs.json?environment_name=${mockEnvName}`;
      mock.onGet(endpoint).replyOnce(500);

      testAction(
        fetchLogs,
        null,
        state,
        [
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
