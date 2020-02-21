import mutations from 'ee/geo_node_form/store/mutations';
import createState from 'ee/geo_node_form/store/state';
import * as types from 'ee/geo_node_form/store/mutation_types';
import { MOCK_SYNC_NAMESPACES } from '../mock_data';

describe('GeoNodeForm Store Mutations', () => {
  let state;
  beforeEach(() => {
    state = createState();
  });

  describe('REQUEST_SYNC_NAMESPACES', () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_SYNC_NAMESPACES](state);
      expect(state.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_SYNC_NAMESPACES_SUCCESS', () => {
    it('sets isLoading to false', () => {
      state.isLoading = true;

      mutations[types.RECEIVE_SYNC_NAMESPACES_SUCCESS](state, MOCK_SYNC_NAMESPACES);
      expect(state.isLoading).toEqual(false);
    });

    it('sets synchronizationNamespaces array with namespace data', () => {
      mutations[types.RECEIVE_SYNC_NAMESPACES_SUCCESS](state, MOCK_SYNC_NAMESPACES);
      expect(state.synchronizationNamespaces).toBe(MOCK_SYNC_NAMESPACES);
    });
  });

  describe('RECEIVE_SYNC_NAMESPACES_ERROR', () => {
    it('sets isLoading to false', () => {
      state.isLoading = true;

      mutations[types.RECEIVE_SYNC_NAMESPACES_ERROR](state);
      expect(state.isLoading).toEqual(false);
    });

    it('resets synchronizationNamespaces array', () => {
      state.synchronizationNamespaces = MOCK_SYNC_NAMESPACES;

      mutations[types.RECEIVE_SYNC_NAMESPACES_ERROR](state);
      expect(state.synchronizationNamespaces).toEqual([]);
    });
  });
});
