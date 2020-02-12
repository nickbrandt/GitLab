import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import flash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import * as actions from 'ee/geo_node_form/store/actions';
import * as types from 'ee/geo_node_form/store/mutation_types';
import createState from 'ee/geo_node_form/store/state';
import { MOCK_SYNC_NAMESPACES } from '../mock_data';

jest.mock('~/flash');

describe('GeoNodeForm Store Actions', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = createState();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('requestSyncNamespaces', () => {
    it('should commit mutation REQUEST_SYNC_NAMESPACES', done => {
      testAction(
        actions.requestSyncNamespaces,
        null,
        state,
        [{ type: types.REQUEST_SYNC_NAMESPACES }],
        [],
        done,
      );
    });
  });

  describe('receiveSyncNamespacesSuccess', () => {
    it('should commit mutation RECEIVE_SYNC_NAMESPACES_SUCCESS', done => {
      testAction(
        actions.receiveSyncNamespacesSuccess,
        MOCK_SYNC_NAMESPACES,
        state,
        [{ type: types.RECEIVE_SYNC_NAMESPACES_SUCCESS, payload: MOCK_SYNC_NAMESPACES }],
        [],
        done,
      );
    });
  });

  describe('receiveSyncNamespacesError', () => {
    it('should commit mutation RECEIVE_SYNC_NAMESPACES_ERROR', () => {
      testAction(
        actions.receiveSyncNamespacesError,
        null,
        state,
        [{ type: types.RECEIVE_SYNC_NAMESPACES_ERROR }],
        [],
        () => {
          expect(flash).toHaveBeenCalledTimes(1);
          flash.mockClear();
        },
      );
    });
  });

  describe('fetchSyncNamespaces', () => {
    describe('on success', () => {
      beforeEach(() => {
        mock.onGet().replyOnce(200, MOCK_SYNC_NAMESPACES);
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.fetchSyncNamespaces,
          {},
          state,
          [],
          [
            { type: 'requestSyncNamespaces' },
            { type: 'receiveSyncNamespacesSuccess', payload: MOCK_SYNC_NAMESPACES },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onGet().replyOnce(500, {});
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.fetchSyncNamespaces,
          {},
          state,
          [],
          [{ type: 'requestSyncNamespaces' }, { type: 'receiveSyncNamespacesError' }],
          done,
        );
      });
    });
  });
});
