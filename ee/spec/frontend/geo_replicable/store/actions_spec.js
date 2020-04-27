import testAction from 'helpers/vuex_action_helper';
import flash from '~/flash';
import toast from '~/vue_shared/plugins/global_toast';
import Api from 'ee/api';
import * as actions from 'ee/geo_replicable/store/actions';
import * as types from 'ee/geo_replicable/store/mutation_types';
import createState from 'ee/geo_replicable/store/state';
import { ACTION_TYPES } from 'ee/geo_replicable/store/constants';
import {
  MOCK_BASIC_FETCH_DATA_MAP,
  MOCK_BASIC_FETCH_RESPONSE,
  MOCK_BASIC_POST_RESPONSE,
  MOCK_REPLICABLE_TYPE,
} from '../mock_data';

jest.mock('~/flash');
jest.mock('~/vue_shared/plugins/global_toast');

describe('GeoReplicable Store Actions', () => {
  let state;

  beforeEach(() => {
    state = createState(MOCK_REPLICABLE_TYPE);
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
        },
      );
    });
  });

  describe('fetchReplicableItems', () => {
    describe('on success', () => {
      beforeEach(() => {
        jest.spyOn(Api, 'getGeoReplicableItems').mockResolvedValue(MOCK_BASIC_FETCH_RESPONSE);
      });

      describe('with no params set', () => {
        const defaultParams = {
          page: 1,
          search: null,
          sync_status: null,
        };

        it('should call getGeoReplicableItems with default queryParams', () => {
          testAction(
            actions.fetchReplicableItems,
            {},
            state,
            [],
            [
              { type: 'requestReplicableItems' },
              { type: 'receiveReplicableItemsSuccess', payload: MOCK_BASIC_FETCH_DATA_MAP },
            ],
            () => {
              expect(Api.getGeoReplicableItems).toHaveBeenCalledWith(
                MOCK_REPLICABLE_TYPE,
                defaultParams,
              );
            },
          );
        });
      });

      describe('with params set', () => {
        beforeEach(() => {
          state.currentPage = 3;
          state.searchFilter = 'test search';
          state.currentFilterIndex = 2;
        });

        it('should call getGeoReplicableItems with default queryParams', () => {
          testAction(
            actions.fetchReplicableItems,
            {},
            state,
            [],
            [
              { type: 'requestReplicableItems' },
              { type: 'receiveReplicableItemsSuccess', payload: MOCK_BASIC_FETCH_DATA_MAP },
            ],
            () => {
              expect(Api.getGeoReplicableItems).toHaveBeenCalledWith(MOCK_REPLICABLE_TYPE, {
                page: 3,
                search: 'test search',
                sync_status: state.filterOptions[2].value,
              });
            },
          );
        });
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        jest.spyOn(Api, 'getGeoReplicableItems').mockRejectedValue(new Error(500));
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.fetchReplicableItems,
          {},
          state,
          [],
          [{ type: 'requestReplicableItems' }, { type: 'receiveReplicableItemsError' }],
          done,
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
        },
      );
    });
  });

  describe('initiateAllReplicableSyncs', () => {
    let action;

    describe('on success', () => {
      beforeEach(() => {
        action = ACTION_TYPES.RESYNC;
        jest
          .spyOn(Api, 'initiateAllGeoReplicableSyncs')
          .mockResolvedValue(MOCK_BASIC_POST_RESPONSE);
      });

      it('should dispatch the request with correct replicable param and success actions', () => {
        testAction(
          actions.initiateAllReplicableSyncs,
          action,
          state,
          [],
          [
            { type: 'requestInitiateAllReplicableSyncs' },
            { type: 'receiveInitiateAllReplicableSyncsSuccess', payload: { action } },
          ],
          () => {
            expect(Api.initiateAllGeoReplicableSyncs).toHaveBeenCalledWith(
              MOCK_REPLICABLE_TYPE,
              action,
            );
          },
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        action = ACTION_TYPES.RESYNC;
        jest.spyOn(Api, 'initiateAllGeoReplicableSyncs').mockRejectedValue(new Error(500));
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.initiateAllReplicableSyncs,
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
        },
      );
    });
  });

  describe('initiateReplicableSync', () => {
    let action;
    let projectId;
    let name;

    describe('on success', () => {
      beforeEach(() => {
        action = ACTION_TYPES.RESYNC;
        projectId = 1;
        name = 'test';
        jest.spyOn(Api, 'initiateGeoReplicableSync').mockResolvedValue(MOCK_BASIC_POST_RESPONSE);
      });

      it('should dispatch the request with correct replicable param and success actions', () => {
        testAction(
          actions.initiateReplicableSync,
          { projectId, name, action },
          state,
          [],
          [
            { type: 'requestInitiateReplicableSync' },
            { type: 'receiveInitiateReplicableSyncSuccess', payload: { name, action } },
          ],
          () => {
            expect(Api.initiateGeoReplicableSync).toHaveBeenCalledWith(MOCK_REPLICABLE_TYPE, {
              projectId,
              action,
            });
          },
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        action = ACTION_TYPES.RESYNC;
        projectId = 1;
        name = 'test';
        jest.spyOn(Api, 'initiateGeoReplicableSync').mockRejectedValue(new Error(500));
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.initiateReplicableSync,
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
