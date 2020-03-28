import MockAdapter from 'axios-mock-adapter';
import testAction from 'spec/helpers/vuex_action_helper';
import { PENDING, RUNNING, STOPPING, STOPPED } from 'ee/ide/constants';
import * as messages from 'ee/ide/stores/modules/terminal/messages';
import * as mutationTypes from 'ee/ide/stores/modules/terminal/mutation_types';
import actionsModule, * as actions from 'ee/ide/stores/modules/terminal/actions/session_status';
import axios from '~/lib/utils/axios_utils';

const TEST_SESSION = {
  id: 7,
  status: PENDING,
  show_path: 'path/show',
  cancel_path: 'path/cancel',
  retry_path: 'path/retry',
  terminal_path: 'path/terminal',
};

describe('EE IDE store terminal session controls actions', () => {
  let mock;
  let dispatch;
  let commit;
  let flashSpy;

  beforeEach(() => {
    jasmine.clock().install();
    mock = new MockAdapter(axios);
    dispatch = jasmine.createSpy('dispatch');
    commit = jasmine.createSpy('commit');
    flashSpy = spyOnDependency(actionsModule, 'flash');
  });

  afterEach(() => {
    jasmine.clock().uninstall();
    mock.restore();
  });

  describe('pollSessionStatus', () => {
    it('starts interval to poll status', done => {
      testAction(
        actions.pollSessionStatus,
        null,
        {},
        [{ type: mutationTypes.SET_SESSION_STATUS_INTERVAL, payload: jasmine.any(Number) }],
        [{ type: 'stopPollingSessionStatus' }, { type: 'fetchSessionStatus' }],
        done,
      );
    });

    it('on interval, stops polling if no session', () => {
      const state = {
        session: null,
      };

      actions.pollSessionStatus({ state, dispatch, commit });
      dispatch.calls.reset();

      jasmine.clock().tick(5001);

      expect(dispatch).toHaveBeenCalledWith('stopPollingSessionStatus');
    });

    it('on interval, fetches status', () => {
      const state = {
        session: TEST_SESSION,
      };

      actions.pollSessionStatus({ state, dispatch, commit });
      dispatch.calls.reset();

      jasmine.clock().tick(5001);

      expect(dispatch).toHaveBeenCalledWith('fetchSessionStatus');
    });
  });

  describe('stopPollingSessionStatus', () => {
    it('does nothing if sessionStatusInterval is empty', done => {
      testAction(actions.stopPollingSessionStatus, null, {}, [], [], done);
    });

    it('clears interval', done => {
      testAction(
        actions.stopPollingSessionStatus,
        null,
        { sessionStatusInterval: 7 },
        [{ type: mutationTypes.SET_SESSION_STATUS_INTERVAL, payload: 0 }],
        [],
        done,
      );
    });
  });

  describe('receiveSessionStatusSuccess', () => {
    it('sets session status', done => {
      testAction(
        actions.receiveSessionStatusSuccess,
        { status: RUNNING },
        {},
        [{ type: mutationTypes.SET_SESSION_STATUS, payload: RUNNING }],
        [],
        done,
      );
    });

    [STOPPING, STOPPED, 'unexpected'].forEach(status => {
      it(`kills session if status is ${status}`, done => {
        testAction(
          actions.receiveSessionStatusSuccess,
          { status },
          {},
          [{ type: mutationTypes.SET_SESSION_STATUS, payload: status }],
          [{ type: 'killSession' }],
          done,
        );
      });
    });
  });

  describe('receiveSessionStatusError', () => {
    it('flashes message', () => {
      actions.receiveSessionStatusError({ dispatch });

      expect(flashSpy).toHaveBeenCalledWith(messages.UNEXPECTED_ERROR_STATUS);
    });

    it('kills the session', done => {
      testAction(actions.receiveSessionStatusError, null, {}, [], [{ type: 'killSession' }], done);
    });
  });

  describe('fetchSessionStatus', () => {
    let state;

    beforeEach(() => {
      state = {
        session: {
          showPath: TEST_SESSION.show_path,
        },
      };
    });

    it('does nothing if session is falsey', () => {
      state.session = null;

      actions.fetchSessionStatus({ dispatch, state });

      expect(dispatch).not.toHaveBeenCalled();
    });

    it('dispatches success on success', done => {
      mock.onGet(state.session.showPath).reply(200, TEST_SESSION);

      testAction(
        actions.fetchSessionStatus,
        null,
        state,
        [],
        [{ type: 'receiveSessionStatusSuccess', payload: TEST_SESSION }],
        done,
      );
    });

    it('dispatches error on error', done => {
      mock.onGet(state.session.showPath).reply(400);

      testAction(
        actions.fetchSessionStatus,
        null,
        state,
        [],
        [{ type: 'receiveSessionStatusError', payload: jasmine.any(Error) }],
        done,
      );
    });
  });
});
