import * as types from 'ee/analytics/code_review_analytics/store/modules/merge_requests/mutation_types';
import mutations from 'ee/analytics/code_review_analytics/store/modules/merge_requests/mutations';
import getInitialState from 'ee/analytics/code_review_analytics/store/modules/merge_requests/state';
import mockMergeRequests from '../../../mock_data';

describe('Code review analytics mutations', () => {
  let state;

  const milestoneTitle = 'my milestone';
  const labelName = ['first label', 'second label'];

  const pageInfo = {
    page: 1,
    nextPage: 2,
    previousPage: 1,
    perPage: 10,
    total: 50,
    totalPages: 5,
  };

  beforeEach(() => {
    state = getInitialState();
  });

  describe(types.SET_PROJECT_ID, () => {
    it('sets the project id', () => {
      mutations[types.SET_PROJECT_ID](state, 1);

      expect(state.projectId).toBe(1);
    });
  });

  describe(types.SET_FILTERS, () => {
    it('updates milestoneTitle and labelName', () => {
      mutations[types.SET_FILTERS](state, { milestoneTitle, labelName });

      expect(state.filters.milestoneTitle).toBe(milestoneTitle);
      expect(state.filters.labelName).toBe(labelName);
      expect(state.pageInfo.page).toBe(1);
    });
  });

  describe(types.REQUEST_MERGE_REQUESTS, () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_MERGE_REQUESTS](state);

      expect(state.isLoading).toBe(true);
    });
  });

  describe(types.RECEIVE_MERGE_REQUESTS_SUCCESS, () => {
    it('updates mergeRequests with the received data and updates the pageInfo', () => {
      mutations[types.RECEIVE_MERGE_REQUESTS_SUCCESS](state, {
        pageInfo,
        mergeRequests: mockMergeRequests,
      });

      expect(state.isLoading).toBe(false);
      expect(state.errorCode).toBe(null);
      expect(state.mergeRequests).toEqual(mockMergeRequests);
      expect(state.pageInfo).toEqual(pageInfo);
    });
  });

  describe(types.RECEIVE_MERGE_REQUESTS_ERROR, () => {
    const errorCode = 500;
    beforeEach(() => {
      mutations[types.RECEIVE_MERGE_REQUESTS_ERROR](state, errorCode);
    });

    it('sets isLoading to false', () => {
      expect(state.isLoading).toBe(false);
    });

    it('sets errorCode to 500', () => {
      expect(state.errorCode).toBe(errorCode);
    });

    it('clears data', () => {
      expect(state.mergeRequests).toEqual([]);
      expect(state.pageInfo).toEqual({});
    });
  });

  describe('SET_PAGE', () => {
    it('sets the page on the pageInfo object', () => {
      mutations[types.SET_PAGE](state, 2);

      expect(state.pageInfo.page).toBe(2);
    });
  });
});
