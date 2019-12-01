import mutations from 'ee/geo_designs/store/mutations';
import createState from 'ee/geo_designs/store/state';
import * as types from 'ee/geo_designs/store/mutation_types';
import { MOCK_BASIC_FETCH_DATA_MAP } from '../mock_data';

describe('GeoDesigns Store Mutations', () => {
  let state;
  beforeEach(() => {
    state = createState();
  });

  describe('SET_PAGE', () => {
    it('sets the page to the correct page', () => {
      mutations[types.SET_PAGE](state, 2);
      expect(state.currentPage).toEqual(2);
    });
  });

  describe('REQUEST_DESIGNS', () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_DESIGNS](state);
      expect(state.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_DESIGNS_SUCCESS', () => {
    let mockData = {};

    beforeEach(() => {
      mockData = MOCK_BASIC_FETCH_DATA_MAP;
    });

    it('sets isLoading to false', () => {
      state.isLoading = true;

      mutations[types.RECEIVE_DESIGNS_SUCCESS](state, mockData);
      expect(state.isLoading).toEqual(false);
    });

    it('sets designs array with design data', () => {
      mutations[types.RECEIVE_DESIGNS_SUCCESS](state, mockData);
      expect(state.designs).toBe(mockData.data);
    });

    it('sets pageSize and totalDesigns', () => {
      mutations[types.RECEIVE_DESIGNS_SUCCESS](state, mockData);
      expect(state.pageSize).toEqual(mockData.perPage);
      expect(state.totalDesigns).toEqual(mockData.total);
    });
  });

  describe('RECEIVE_DESIGNS_ERROR', () => {
    let mockData = {};

    beforeEach(() => {
      mockData = MOCK_BASIC_FETCH_DATA_MAP;
    });

    it('sets isLoading to false', () => {
      state.isLoading = true;

      mutations[types.RECEIVE_DESIGNS_ERROR](state);
      expect(state.isLoading).toEqual(false);
    });

    it('resets designs array', () => {
      state.designs = mockData.data;

      mutations[types.RECEIVE_DESIGNS_ERROR](state);
      expect(state.designs).toEqual([]);
    });

    it('resets pagination data', () => {
      state.pageSize = mockData.perPage;
      state.totalDesigns = mockData.total;

      mutations[types.RECEIVE_DESIGNS_ERROR](state);
      expect(state.pageSize).toEqual(0);
      expect(state.totalDesigns).toEqual(0);
    });
  });
});
