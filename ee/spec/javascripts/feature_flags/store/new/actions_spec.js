import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import actions, {
  setEndpoint,
  setPath,
  createFeatureFlag,
  requestCreateFeatureFlag,
  receiveCreateFeatureFlagSuccess,
  receiveCreateFeatureFlagError,
} from 'ee/feature_flags/store/modules/new/actions';
import state from 'ee/feature_flags/store/modules/new/state';
import * as types from 'ee/feature_flags/store/modules/new/mutation_types';
import testAction from 'spec/helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';

describe('Feature flags New Module Actions', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe('setEndpoint', () => {
    it('should commit SET_ENDPOINT mutation', done => {
      testAction(
        setEndpoint,
        'feature_flags.json',
        mockedState,
        [{ type: types.SET_ENDPOINT, payload: 'feature_flags.json' }],
        [],
        done,
      );
    });
  });

  describe('setPath', () => {
    it('should commit SET_PATH mutation', done => {
      testAction(
        setPath,
        '/feature_flags',
        mockedState,
        [{ type: types.SET_PATH, payload: '/feature_flags' }],
        [],
        done,
      );
    });
  });

  describe('createFeatureFlag', () => {
    let mock;

    beforeEach(() => {
      mockedState.endpoint = `${TEST_HOST}/endpoint.json`;
      mock = new MockAdapter(axios);
      spyOnDependency(actions, 'visitUrl');
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('dispatches requestCreateFeatureFlag and receiveCreateFeatureFlagSuccess ', done => {
        mock
          .onPost(`${TEST_HOST}/endpoint.json`, {
            operations_feature_flag: {
              name: 'feature_flag',
              description: 'feature flag',
              scopes_attributes: [{ environment_scope: '*', active: true }],
            },
          })
          .replyOnce(200);

        testAction(
          createFeatureFlag,
          {
            name: 'feature_flag',
            description: 'feature flag',
            scopes: [{ environment_scope: '*', active: true }],
          },
          mockedState,
          [],
          [
            {
              type: 'requestCreateFeatureFlag',
            },
            {
              type: 'receiveCreateFeatureFlagSuccess',
            },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      it('dispatches requestCreateFeatureFlag and receiveCreateFeatureFlagError ', done => {
        mock
          .onPost(`${TEST_HOST}/endpoint.json`, {
            operations_feature_flag: {
              name: 'feature_flag',
              description: 'feature flag',
              scopes_attributes: [{ environment_scope: '*', active: true }],
            },
          })
          .replyOnce(500, { message: [] });

        testAction(
          createFeatureFlag,
          {
            name: 'feature_flag',
            description: 'feature flag',
            scopes: [{ environment_scope: '*', active: true }],
          },
          mockedState,
          [],
          [
            {
              type: 'requestCreateFeatureFlag',
            },
            {
              type: 'receiveCreateFeatureFlagError',
              payload: { message: [] },
            },
          ],
          done,
        );
      });
    });
  });

  describe('requestCreateFeatureFlag', () => {
    it('should commit REQUEST_CREATE_FEATURE_FLAG mutation', done => {
      testAction(
        requestCreateFeatureFlag,
        null,
        mockedState,
        [{ type: types.REQUEST_CREATE_FEATURE_FLAG }],
        [],
        done,
      );
    });
  });

  describe('receiveCreateFeatureFlagSuccess', () => {
    it('should commit RECEIVE_CREATE_FEATURE_FLAG_SUCCESS mutation', done => {
      testAction(
        receiveCreateFeatureFlagSuccess,
        null,
        mockedState,
        [
          {
            type: types.RECEIVE_CREATE_FEATURE_FLAG_SUCCESS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveCreateFeatureFlagError', () => {
    it('should commit RECEIVE_CREATE_FEATURE_FLAG_ERROR mutation', done => {
      testAction(
        receiveCreateFeatureFlagError,
        'There was an error',
        mockedState,
        [{ type: types.RECEIVE_CREATE_FEATURE_FLAG_ERROR, payload: 'There was an error' }],
        [],
        done,
      );
    });
  });
});
