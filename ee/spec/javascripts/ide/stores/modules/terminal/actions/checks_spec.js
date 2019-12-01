import MockAdapter from 'axios-mock-adapter';
import testAction from 'spec/helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';
import { CHECK_CONFIG, CHECK_RUNNERS, RETRY_RUNNERS_INTERVAL } from 'ee/ide/constants';
import * as mutationTypes from 'ee/ide/stores/modules/terminal/mutation_types';
import * as messages from 'ee/ide/stores/modules/terminal/messages';
import * as actions from 'ee/ide/stores/modules/terminal/actions/checks';
import axios from '~/lib/utils/axios_utils';
import httpStatus from '~/lib/utils/http_status';

const TEST_PROJECT_PATH = 'lorem/root';
const TEST_BRANCH_ID = 'master';
const TEST_YAML_HELP_PATH = `${TEST_HOST}/test/yaml/help`;
const TEST_RUNNERS_HELP_PATH = `${TEST_HOST}/test/runners/help`;

describe('EE IDE store terminal check actions', () => {
  let mock;
  let state;
  let rootState;
  let rootGetters;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    state = {
      paths: {
        webTerminalConfigHelpPath: TEST_YAML_HELP_PATH,
        webTerminalRunnersHelpPath: TEST_RUNNERS_HELP_PATH,
      },
      checks: {
        config: { isLoading: true },
      },
    };
    rootState = {
      currentBranchId: TEST_BRANCH_ID,
    };
    rootGetters = {
      currentProject: {
        id: 7,
        path_with_namespace: TEST_PROJECT_PATH,
      },
    };
    jasmine.clock().install();
  });

  afterEach(() => {
    mock.restore();
    jasmine.clock().uninstall();
  });

  describe('requestConfigCheck', () => {
    it('handles request loading', done => {
      testAction(
        actions.requestConfigCheck,
        null,
        {},
        [{ type: mutationTypes.REQUEST_CHECK, payload: CHECK_CONFIG }],
        [],
        done,
      );
    });
  });

  describe('receiveConfigCheckSuccess', () => {
    it('handles successful response', done => {
      testAction(
        actions.receiveConfigCheckSuccess,
        null,
        {},
        [
          { type: mutationTypes.SET_VISIBLE, payload: true },
          { type: mutationTypes.RECEIVE_CHECK_SUCCESS, payload: CHECK_CONFIG },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveConfigCheckError', () => {
    it('handles error response', done => {
      const status = httpStatus.UNPROCESSABLE_ENTITY;
      const payload = { response: { status } };

      testAction(
        actions.receiveConfigCheckError,
        payload,
        state,
        [
          {
            type: mutationTypes.SET_VISIBLE,
            payload: true,
          },
          {
            type: mutationTypes.RECEIVE_CHECK_ERROR,
            payload: {
              type: CHECK_CONFIG,
              message: messages.configCheckError(status, TEST_YAML_HELP_PATH),
            },
          },
        ],
        [],
        done,
      );
    });

    [httpStatus.FORBIDDEN, httpStatus.NOT_FOUND].forEach(status => {
      it(`hides tab, when status is ${status}`, done => {
        const payload = { response: { status } };

        testAction(
          actions.receiveConfigCheckError,
          payload,
          state,
          [
            {
              type: mutationTypes.SET_VISIBLE,
              payload: false,
            },
            jasmine.objectContaining({ type: mutationTypes.RECEIVE_CHECK_ERROR }),
          ],
          [],
          done,
        );
      });
    });
  });

  describe('fetchConfigCheck', () => {
    it('dispatches request and receive', done => {
      mock.onPost(/.*\/ide_terminals\/check_config/).reply(200, {});

      testAction(
        actions.fetchConfigCheck,
        null,
        {
          ...rootGetters,
          ...rootState,
        },
        [],
        [{ type: 'requestConfigCheck' }, { type: 'receiveConfigCheckSuccess' }],
        done,
      );
    });

    it('when error, dispatches request and receive', done => {
      mock.onPost(/.*\/ide_terminals\/check_config/).reply(400, {});

      testAction(
        actions.fetchConfigCheck,
        null,
        {
          ...rootGetters,
          ...rootState,
        },
        [],
        [
          { type: 'requestConfigCheck' },
          { type: 'receiveConfigCheckError', payload: jasmine.any(Error) },
        ],
        done,
      );
    });
  });

  describe('requestRunnersCheck', () => {
    it('handles request loading', done => {
      testAction(
        actions.requestRunnersCheck,
        null,
        {},
        [{ type: mutationTypes.REQUEST_CHECK, payload: CHECK_RUNNERS }],
        [],
        done,
      );
    });
  });

  describe('receiveRunnersCheckSuccess', () => {
    it('handles successful response, with data', done => {
      const payload = [{}];

      testAction(
        actions.receiveRunnersCheckSuccess,
        payload,
        state,
        [{ type: mutationTypes.RECEIVE_CHECK_SUCCESS, payload: CHECK_RUNNERS }],
        [],
        done,
      );
    });

    it('handles successful response, with empty data', done => {
      const commitPayload = {
        type: CHECK_RUNNERS,
        message: messages.runnersCheckEmpty(TEST_RUNNERS_HELP_PATH),
      };

      testAction(
        actions.receiveRunnersCheckSuccess,
        [],
        state,
        [{ type: mutationTypes.RECEIVE_CHECK_ERROR, payload: commitPayload }],
        [{ type: 'retryRunnersCheck' }],
        done,
      );
    });
  });

  describe('receiveRunnersCheckError', () => {
    it('dispatches handle with message', done => {
      const commitPayload = {
        type: CHECK_RUNNERS,
        message: messages.UNEXPECTED_ERROR_RUNNERS,
      };

      testAction(
        actions.receiveRunnersCheckError,
        null,
        {},
        [{ type: mutationTypes.RECEIVE_CHECK_ERROR, payload: commitPayload }],
        [],
        done,
      );
    });
  });

  describe('retryRunnersCheck', () => {
    it('dispatches fetch again after timeout', () => {
      const dispatch = jasmine.createSpy('dispatch');

      actions.retryRunnersCheck({ dispatch, state });

      expect(dispatch).not.toHaveBeenCalled();

      jasmine.clock().tick(RETRY_RUNNERS_INTERVAL + 1);

      expect(dispatch).toHaveBeenCalledWith('fetchRunnersCheck', { background: true });
    });

    it('does not dispatch fetch if config check is error', () => {
      const dispatch = jasmine.createSpy('dispatch');
      state.checks.config = {
        isLoading: false,
        isValid: false,
      };

      actions.retryRunnersCheck({ dispatch, state });

      expect(dispatch).not.toHaveBeenCalled();

      jasmine.clock().tick(RETRY_RUNNERS_INTERVAL + 1);

      expect(dispatch).not.toHaveBeenCalled();
    });
  });

  describe('fetchRunnersCheck', () => {
    it('dispatches request and receive', done => {
      mock.onGet(/api\/.*\/projects\/.*\/runners/, { params: { scope: 'active' } }).reply(200, []);

      testAction(
        actions.fetchRunnersCheck,
        {},
        rootGetters,
        [],
        [{ type: 'requestRunnersCheck' }, { type: 'receiveRunnersCheckSuccess', payload: [] }],
        done,
      );
    });

    it('does not dispatch request when background is true', done => {
      mock.onGet(/api\/.*\/projects\/.*\/runners/, { params: { scope: 'active' } }).reply(200, []);

      testAction(
        actions.fetchRunnersCheck,
        { background: true },
        rootGetters,
        [],
        [{ type: 'receiveRunnersCheckSuccess', payload: [] }],
        done,
      );
    });

    it('dispatches request and receive, when error', done => {
      mock.onGet(/api\/.*\/projects\/.*\/runners/, { params: { scope: 'active' } }).reply(500, []);

      testAction(
        actions.fetchRunnersCheck,
        {},
        rootGetters,
        [],
        [
          { type: 'requestRunnersCheck' },
          { type: 'receiveRunnersCheckError', payload: jasmine.any(Error) },
        ],
        done,
      );
    });
  });
});
