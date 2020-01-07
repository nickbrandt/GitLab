import mutations from 'ee/geo_designs/store/mutations';
import createState from 'ee/geo_designs/store/state';
import * as types from 'ee/geo_designs/store/mutation_types';
import { MOCK_BASIC_FETCH_DATA_MAP } from '../mock_data';

describe('GeoDesigns Store Mutations', () => {
  let state;
  beforeEach(() => {
    state = createState();
  });

  describe('SET_FILTER', () => {
    const testValue = 2;

    beforeEach(() => {
      state.currentFilterIndex = 1;
      state.currentPage = 2;

      mutations[types.SET_FILTER](state, testValue);
    });

    it('sets the currentFilterIndex state key', () => {
      expect(state.currentFilterIndex).toEqual(testValue);
    });

    it('resets the page to 1', () => {
      expect(state.currentPage).toEqual(1);
    });
  });

  describe('SET_SEARCH', () => {
    const testValue = 'test search';

    beforeEach(() => {
      state.currentPage = 2;

      mutations[types.SET_SEARCH](state, testValue);
    });

    it('sets the searchFilter state key', () => {
      expect(state.searchFilter).toEqual(testValue);
    });

    it('resets the page to 1', () => {
      expect(state.currentPage).toEqual(1);
    });
  });

  describe('SET_PAGE', () => {
    it('sets the currentPage state key', () => {
      const testValue = 2;

      mutations[types.SET_PAGE](state, testValue);
      expect(state.currentPage).toEqual(testValue);
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

  describe.each`
    mutation                                           | loadingBefore | loadingAfter
    ${types.REQUEST_INITIATE_ALL_DESIGN_SYNCS}         | ${false}      | ${true}
    ${types.RECEIVE_INITIATE_ALL_DESIGN_SYNCS_SUCCESS} | ${true}       | ${false}
    ${types.RECEIVE_INITIATE_ALL_DESIGN_SYNCS_ERROR}   | ${true}       | ${false}
    ${types.REQUEST_INITIATE_DESIGN_SYNC}              | ${false}      | ${true}
    ${types.RECEIVE_INITIATE_DESIGN_SYNC_SUCCESS}      | ${true}       | ${false}
    ${types.RECEIVE_INITIATE_DESIGN_SYNC_ERROR}        | ${true}       | ${false}
  `(`Sync Mutations: `, ({ mutation, loadingBefore, loadingAfter }) => {
    describe(`${mutation}`, () => {
      it(`sets isLoading to ${loadingAfter}`, () => {
        state.isLoading = loadingBefore;

        mutations[mutation](state);
        expect(state.isLoading).toEqual(loadingAfter);
      });
    });
  });
});
