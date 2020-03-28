import MockAdapter from 'axios-mock-adapter';
import testAction from 'spec/helpers/vuex_action_helper';
import { STARTING, PENDING, STOPPING, STOPPED } from 'ee/ide/constants';
import * as messages from 'ee/ide/stores/modules/terminal/messages';
import * as mutationTypes from 'ee/ide/stores/modules/terminal/mutation_types';
import actionsModule, * as actions from 'ee/ide/stores/modules/terminal/actions/session_controls';
import httpStatus from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';

const TEST_PROJECT_PATH = 'lorem/root';
const TEST_BRANCH_ID = 'master';
const TEST_SESSION = {
  id: 7,
  status: PENDING,
  show_path: 'path/show',
  cancel_path: 'path/cancel',
  retry_path: 'path/retry',
  terminal_path: 'path/terminal',
  proxy_websocket_path: 'path/proxy',
  services: ['test-service'],
};

describe('EE IDE store terminal session controls actions', () => {
  let mock;
  let dispatch;
  let rootState;
  let rootGetters;
  let flashSpy;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    dispatch = jasmine.createSpy('dispatch');
    rootState = {
      currentBranchId: TEST_BRANCH_ID,
    };
    rootGetters = {
      currentProject: {
        id: 7,
        path_with_namespace: TEST_PROJECT_PATH,
      },
    };
    flashSpy = spyOnDependency(actionsModule, 'flash');
  });

  afterEach(() => {
    mock.restore();
  });

  describe('requestStartSession', () => {
    it('sets session status', done => {
      testAction(
        actions.requestStartSession,
        null,
        {},
        [{ type: mutationTypes.SET_SESSION_STATUS, payload: STARTING }],
        [],
        done,
      );
    });
  });

  describe('receiveStartSessionSuccess', () => {
    it('sets session and starts polling status', done => {
      testAction(
        actions.receiveStartSessionSuccess,
        TEST_SESSION,
        {},
        [
          {
            type: mutationTypes.SET_SESSION,
            payload: {
              id: TEST_SESSION.id,
              status: TEST_SESSION.status,
              showPath: TEST_SESSION.show_path,
              cancelPath: TEST_SESSION.cancel_path,
              retryPath: TEST_SESSION.retry_path,
              terminalPath: TEST_SESSION.terminal_path,
              proxyWebsocketPath: TEST_SESSION.proxy_websocket_path,
              services: TEST_SESSION.services,
            },
          },
        ],
        [{ type: 'pollSessionStatus' }],
        done,
      );
    });
  });

  describe('receiveStartSessionError', () => {
    it('flashes message', () => {
      actions.receiveStartSessionError({ dispatch });

      expect(flashSpy).toHaveBeenCalledWith(messages.UNEXPECTED_ERROR_STARTING);
    });

    it('sets session status', done => {
      testAction(actions.receiveStartSessionError, null, {}, [], [{ type: 'killSession' }], done);
    });
  });

  describe('startSession', () => {
    it('does nothing if session is already starting', () => {
      const state = {
        session: { status: STARTING },
      };

      actions.startSession({ state, dispatch });

      expect(dispatch).not.toHaveBeenCalled();
    });

    it('dispatches request and receive on success', done => {
      mock.onPost(/.*\/ide_terminals/).reply(200, TEST_SESSION);

      testAction(
        actions.startSession,
        null,
        { ...rootGetters, ...rootState },
        [],
        [
          { type: 'requestStartSession' },
          { type: 'receiveStartSessionSuccess', payload: TEST_SESSION },
        ],
        done,
      );
    });

    it('dispatches request and receive on error', done => {
      mock.onPost(/.*\/ide_terminals/).reply(400);

      testAction(
        actions.startSession,
        null,
        { ...rootGetters, ...rootState },
        [],
        [
          { type: 'requestStartSession' },
          { type: 'receiveStartSessionError', payload: jasmine.any(Error) },
        ],
        done,
      );
    });
  });

  describe('requestStopSession', () => {
    it('sets session status', done => {
      testAction(
        actions.requestStopSession,
        null,
        {},
        [{ type: mutationTypes.SET_SESSION_STATUS, payload: STOPPING }],
        [],
        done,
      );
    });
  });

  describe('receiveStopSessionSuccess', () => {
    it('kills the session', done => {
      testAction(actions.receiveStopSessionSuccess, null, {}, [], [{ type: 'killSession' }], done);
    });
  });

  describe('receiveStopSessionError', () => {
    it('flashes message', () => {
      actions.receiveStopSessionError({ dispatch });

      expect(flashSpy).toHaveBeenCalledWith(messages.UNEXPECTED_ERROR_STOPPING);
    });

    it('kills the session', done => {
      testAction(actions.receiveStopSessionError, null, {}, [], [{ type: 'killSession' }], done);
    });
  });

  describe('stopSession', () => {
    it('dispatches request and receive on success', done => {
      mock.onPost(TEST_SESSION.cancel_path).reply(200, {});

      const state = {
        session: { cancelPath: TEST_SESSION.cancel_path },
      };

      testAction(
        actions.stopSession,
        null,
        state,
        [],
        [{ type: 'requestStopSession' }, { type: 'receiveStopSessionSuccess' }],
        done,
      );
    });

    it('dispatches request and receive on error', done => {
      mock.onPost(TEST_SESSION.cancel_path).reply(400);

      const state = {
        session: { cancelPath: TEST_SESSION.cancel_path },
      };

      testAction(
        actions.stopSession,
        null,
        state,
        [],
        [
          { type: 'requestStopSession' },
          { type: 'receiveStopSessionError', payload: jasmine.any(Error) },
        ],
        done,
      );
    });
  });

  describe('killSession', () => {
    it('stops polling and sets status', done => {
      testAction(
        actions.killSession,
        null,
        {},
        [{ type: mutationTypes.SET_SESSION_STATUS, payload: STOPPED }],
        [{ type: 'stopPollingSessionStatus' }],
        done,
      );
    });
  });

  describe('restartSession', () => {
    let state;

    beforeEach(() => {
      state = {
        session: { status: STOPPED, retryPath: 'test/retry' },
      };
    });

    it('does nothing if current not stopped', () => {
      state.session.status = STOPPING;

      actions.restartSession({ state, dispatch, rootState });

      expect(dispatch).not.toHaveBeenCalled();
    });

    it('dispatches startSession if retryPath is empty', done => {
      state.session.retryPath = '';

      testAction(
        actions.restartSession,
        null,
        { ...state, ...rootState },
        [],
        [{ type: 'startSession' }],
        done,
      );
    });

    it('dispatches request and receive on success', done => {
      mock
        .onPost(state.session.retryPath, { branch: rootState.currentBranchId, format: 'json' })
        .reply(200, TEST_SESSION);

      testAction(
        actions.restartSession,
        null,
        { ...state, ...rootState },
        [],
        [
          { type: 'requestStartSession' },
          { type: 'receiveStartSessionSuccess', payload: TEST_SESSION },
        ],
        done,
      );
    });

    it('dispatches request and receive on error', done => {
      mock
        .onPost(state.session.retryPath, { branch: rootState.currentBranchId, format: 'json' })
        .reply(400);

      testAction(
        actions.restartSession,
        null,
        { ...state, ...rootState },
        [],
        [
          { type: 'requestStartSession' },
          { type: 'receiveStartSessionError', payload: jasmine.any(Error) },
        ],
        done,
      );
    });

    [httpStatus.NOT_FOUND, httpStatus.UNPROCESSABLE_ENTITY].forEach(status => {
      it(`dispatches request and startSession on ${status}`, done => {
        mock
          .onPost(state.session.retryPath, { branch: rootState.currentBranchId, format: 'json' })
          .reply(status);

        testAction(
          actions.restartSession,
          null,
          { ...state, ...rootState },
          [],
          [{ type: 'requestStartSession' }, { type: 'startSession' }],
          done,
        );
      });
    });
  });
});
