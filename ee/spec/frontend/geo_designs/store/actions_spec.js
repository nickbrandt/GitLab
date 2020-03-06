import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import flash from '~/flash';
import toast from '~/vue_shared/plugins/global_toast';
import axios from '~/lib/utils/axios_utils';
import * as actions from 'ee/geo_designs/store/actions';
import * as types from 'ee/geo_designs/store/mutation_types';
import createState from 'ee/geo_designs/store/state';
import { ACTION_TYPES } from 'ee/geo_designs/store/constants';
import {
  MOCK_BASIC_FETCH_DATA_MAP,
  MOCK_BASIC_FETCH_RESPONSE,
  MOCK_BASIC_POST_RESPONSE,
} from '../mock_data';

jest.mock('~/flash');
jest.mock('~/vue_shared/plugins/global_toast');

describe('GeoDesigns Store Actions', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = createState();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('requestReplicableItems', () => {
    it('should commit mutation REQUEST_REPLICABLE_ITEMS', done => {
      testAction(
        actions.requestReplicableItems,
        null,
        state,
        [{ type: types.REQUEST_REPLICABLE_ITEMS }],
        [],
        done,
      );
    });
  });

  describe('receiveReplicableItemsSuccess', () => {
    it('should commit mutation RECEIVE_REPLICABLE_ITEMS_SUCCESS', done => {
      testAction(
        actions.receiveReplicableItemsSuccess,
        MOCK_BASIC_FETCH_DATA_MAP,
        state,
        [{ type: types.RECEIVE_REPLICABLE_ITEMS_SUCCESS, payload: MOCK_BASIC_FETCH_DATA_MAP }],
        [],
        done,
      );
    });
  });

  describe('receiveReplicableItemsError', () => {
    it('should commit mutation RECEIVE_REPLICABLE_ITEMS_ERROR', () => {
      testAction(
        actions.receiveReplicableItemsError,
        null,
        state,
        [{ type: types.RECEIVE_REPLICABLE_ITEMS_ERROR }],
        [],
        () => {
          expect(flash).toHaveBeenCalledTimes(1);
          flash.mockClear();
        },
      );
    });
  });

  describe('fetchDesigns', () => {
    describe('on success', () => {
      beforeEach(() => {
        mock
          .onGet()
          .replyOnce(200, MOCK_BASIC_FETCH_RESPONSE.data, MOCK_BASIC_FETCH_RESPONSE.headers);
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.fetchDesigns,
          {},
          state,
          [],
          [
            { type: 'requestReplicableItems' },
            { type: 'receiveReplicableItemsSuccess', payload: MOCK_BASIC_FETCH_DATA_MAP },
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
          actions.fetchDesigns,
          {},
          state,
          [],
          [{ type: 'requestReplicableItems' }, { type: 'receiveReplicableItemsError' }],
          done,
        );
      });
    });
  });

  describe('queryParams', () => {
    beforeEach(() => {
      mock
        .onGet()
        .replyOnce(200, MOCK_BASIC_FETCH_RESPONSE.data, MOCK_BASIC_FETCH_RESPONSE.headers);
    });

    describe('no params set', () => {
      it('should call fetchDesigns with default queryParams', () => {
        state.isLoading = true;

        function fetchDesignsCall() {
          const callHistory = mock.history.get[0];

          expect(callHistory.params.page).toEqual(1);
          expect(callHistory.params.search).toBeNull();
          expect(callHistory.params.sync_status).toBeNull();
        }

        testAction(
          actions.fetchDesigns,
          {},
          state,
          [],
          [
            { type: 'requestReplicableItems' },
            { type: 'receiveReplicableItemsSuccess', payload: MOCK_BASIC_FETCH_DATA_MAP },
          ],
          fetchDesignsCall,
        );
      });
    });

    describe('with params set', () => {
      it('should call fetchDesigns with queryParams', () => {
        state.isLoading = true;
        state.currentPage = 3;
        state.searchFilter = 'test search';
        state.currentFilterIndex = 2;

        function fetchDesignsCall() {
          const callHistory = mock.history.get[0];

          expect(callHistory.params.page).toEqual(state.currentPage);
          expect(callHistory.params.search).toEqual(state.searchFilter);
          expect(callHistory.params.sync_status).toEqual(
            state.filterOptions[state.currentFilterIndex],
          );
        }

        testAction(
          actions.fetchDesigns,
          {},
          state,
          [],
          [
            { type: 'requestReplicableItems' },
            { type: 'receiveReplicableItemsSuccess', payload: MOCK_BASIC_FETCH_DATA_MAP },
          ],
          fetchDesignsCall,
        );
      });
    });
  });

  describe('requestInitiateAllReplicableSyncs', () => {
    it('should commit mutation REQUEST_INITIATE_ALL_REPLICABLE_SYNCS', done => {
      testAction(
        actions.requestInitiateAllReplicableSyncs,
        null,
        state,
        [{ type: types.REQUEST_INITIATE_ALL_REPLICABLE_SYNCS }],
        [],
        done,
      );
    });
  });

  describe('receiveInitiateAllReplicableSyncsSuccess', () => {
    it('should commit mutation RECEIVE_INITIATE_ALL_REPLICABLE_SYNCS_SUCCESS and call fetchReplicableItems and toast', () => {
      testAction(
        actions.receiveInitiateAllReplicableSyncsSuccess,
        { action: ACTION_TYPES.RESYNC },
        state,
        [{ type: types.RECEIVE_INITIATE_ALL_REPLICABLE_SYNCS_SUCCESS }],
        [{ type: 'fetchReplicableItems' }],
        () => {
          expect(toast).toHaveBeenCalledTimes(1);
          toast.mockClear();
        },
      );
    });
  });

  describe('receiveInitiateAllReplicableSyncsError', () => {
    it('should commit mutation RECEIVE_INITIATE_ALL_REPLICABLE_SYNCS_ERROR', () => {
      testAction(
        actions.receiveInitiateAllReplicableSyncsError,
        ACTION_TYPES.RESYNC,
        state,
        [{ type: types.RECEIVE_INITIATE_ALL_REPLICABLE_SYNCS_ERROR }],
        [],
        () => {
          expect(flash).toHaveBeenCalledTimes(1);
          flash.mockClear();
        },
      );
    });
  });

  describe('initiateAllDesignSyncs', () => {
    let action;

    describe('on success', () => {
      beforeEach(() => {
        action = ACTION_TYPES.RESYNC;

        mock.onPost().replyOnce(201, MOCK_BASIC_POST_RESPONSE);
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.initiateAllDesignSyncs,
          action,
          state,
          [],
          [
            { type: 'requestInitiateAllReplicableSyncs' },
            { type: 'receiveInitiateAllReplicableSyncsSuccess', payload: { action } },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        action = ACTION_TYPES.RESYNC;

        mock.onPost().replyOnce(500);
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.initiateAllDesignSyncs,
          action,
          state,
          [],
          [
            { type: 'requestInitiateAllReplicableSyncs' },
            { type: 'receiveInitiateAllReplicableSyncsError' },
          ],
          done,
        );
      });
    });
  });

  describe('requestInitiateReplicableSync', () => {
    it('should commit mutation REQUEST_INITIATE_REPLICABLE_SYNC', done => {
      testAction(
        actions.requestInitiateReplicableSync,
        null,
        state,
        [{ type: types.REQUEST_INITIATE_REPLICABLE_SYNC }],
        [],
        done,
      );
    });
  });

  describe('receiveInitiateReplicableSyncSuccess', () => {
    it('should commit mutation RECEIVE_INITIATE_REPLICABLE_SYNC_SUCCESS and call fetchReplicableItems and toast', () => {
      testAction(
        actions.receiveInitiateReplicableSyncSuccess,
        { action: ACTION_TYPES.RESYNC, projectName: 'test' },
        state,
        [{ type: types.RECEIVE_INITIATE_REPLICABLE_SYNC_SUCCESS }],
        [{ type: 'fetchReplicableItems' }],
        () => {
          expect(toast).toHaveBeenCalledTimes(1);
          toast.mockClear();
        },
      );
    });
  });

  describe('receiveInitiateReplicableSyncError', () => {
    it('should commit mutation RECEIVE_INITIATE_REPLICABLE_SYNC_ERROR', () => {
      testAction(
        actions.receiveInitiateReplicableSyncError,
        { action: ACTION_TYPES.RESYNC, projectId: 1, projectName: 'test' },
        state,
        [{ type: types.RECEIVE_INITIATE_REPLICABLE_SYNC_ERROR }],
        [],
        () => {
          expect(flash).toHaveBeenCalledTimes(1);
          flash.mockClear();
        },
      );
    });
  });

  describe('initiateDesignSync', () => {
    let action;
    let projectId;
    let name;

    describe('on success', () => {
      beforeEach(() => {
        action = ACTION_TYPES.RESYNC;
        projectId = 1;
        name = 'test';

        mock.onPut().replyOnce(201, MOCK_BASIC_POST_RESPONSE);
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.initiateDesignSync,
          { projectId, name, action },
          state,
          [],
          [
            { type: 'requestInitiateReplicableSync' },
            { type: 'receiveInitiateReplicableSyncSuccess', payload: { name, action } },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        action = ACTION_TYPES.RESYNC;
        projectId = 1;
        name = 'test';

        mock.onPut().replyOnce(500);
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.initiateDesignSync,
          { projectId, name, action },
          state,
          [],
          [
            { type: 'requestInitiateReplicableSync' },
            {
              type: 'receiveInitiateReplicableSyncError',
              payload: { name: 'test' },
            },
          ],
          done,
        );
      });
    });
  });

  describe('setFilter', () => {
    it('should commit mutation SET_FILTER', done => {
      const testValue = 1;

      testAction(
        actions.setFilter,
        testValue,
        state,
        [{ type: types.SET_FILTER, payload: testValue }],
        [],
        done,
      );
    });
  });

  describe('setSearch', () => {
    it('should commit mutation SET_SEARCH', done => {
      const testValue = 'Test Search';

      testAction(
        actions.setSearch,
        testValue,
        state,
        [{ type: types.SET_SEARCH, payload: testValue }],
        [],
        done,
      );
    });
  });

  describe('setPage', () => {
    it('should commit mutation SET_PAGE', done => {
      state.currentPage = 1;

      const testValue = 2;

      testAction(
        actions.setPage,
        testValue,
        state,
        [{ type: types.SET_PAGE, payload: testValue }],
        [],
        done,
      );
    });
  });
});
