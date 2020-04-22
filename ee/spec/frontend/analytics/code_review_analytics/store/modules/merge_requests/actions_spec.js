import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from 'ee/analytics/code_review_analytics/store/modules/merge_requests/actions';
import * as types from 'ee/analytics/code_review_analytics/store/modules/merge_requests/mutation_types';
import getInitialState from 'ee/analytics/code_review_analytics/store/modules/merge_requests/state';
import createFlash from '~/flash';
import mockMergeRequests from '../../../mock_data';

jest.mock('~/flash', () => jest.fn());

describe('Code review analytics actions', () => {
  let state;
  let mock;

  const pageInfo = {
    page: 1,
    nextPage: 2,
    previousPage: 1,
    perPage: 10,
    total: 50,
    totalPages: 5,
  };

  const headers = {
    'X-Next-Page': pageInfo.nextPage,
    'X-Page': pageInfo.page,
    'X-Per-Page': pageInfo.perPage,
    'X-Prev-Page': pageInfo.previousPage,
    'X-Total': pageInfo.total,
    'X-Total-Pages': pageInfo.totalPages,
  };

  beforeEach(() => {
    state = getInitialState();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    createFlash.mockClear();
  });

  describe('setProjectId', () => {
    it('commits the SET_PROJECT_ID mutation', () =>
      testAction(
        actions.setProjectId,
        1,
        state,
        [
          {
            type: types.SET_PROJECT_ID,
            payload: 1,
          },
        ],
        [],
      ));
  });

  describe('fetchMergeRequests', () => {
    describe('success', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/analytics\/code_review/).replyOnce(200, mockMergeRequests, headers);
      });

      it('dispatches success with received data', () => {
        testAction(
          actions.fetchMergeRequests,
          null,
          state,
          [],
          [
            { type: 'requestMergeRequests' },
            { type: 'receiveMergeRequestsSuccess', payload: { headers, data: mockMergeRequests } },
          ],
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/analytics\/code_review/).replyOnce(500);
      });

      it('dispatches error', () => {
        testAction(
          actions.fetchMergeRequests,
          null,
          state,
          [],
          [
            { type: 'requestMergeRequests' },
            {
              type: 'receiveMergeRequestsError',
              payload: new Error('Request failed with status code 500'),
            },
          ],
        );
      });
    });
  });

  describe('requestMergeRequests', () => {
    it('commits REQUEST_MERGE_REQUESTS mutation', () => {
      testAction(
        actions.requestMergeRequests,
        null,
        state,
        [{ type: types.REQUEST_MERGE_REQUESTS }],
        [],
      );
    });
  });

  describe('receiveMergeRequestsSuccess', () => {
    it('commits RECEIVE_MERGE_REQUESTS_SUCCESS mutation', () => {
      testAction(
        actions.receiveMergeRequestsSuccess,
        { headers, data: mockMergeRequests },
        state,
        [
          {
            type: types.RECEIVE_MERGE_REQUESTS_SUCCESS,
            payload: { pageInfo, mergeRequests: mockMergeRequests },
          },
        ],
        [],
      );
    });
  });

  describe('receiveMergeRequestsError', () => {
    it('commits SET_MERGE_REQUEST_ERROR mutation', () =>
      testAction(
        actions.receiveMergeRequestsError,
        { response: { status: 500 } },
        state,
        [{ type: types.RECEIVE_MERGE_REQUESTS_ERROR, payload: 500 }],
        [],
      ).then(() => {
        expect(createFlash).toHaveBeenCalled();
      }));
  });

  describe('setFilters', () => {
    const milestoneTitle = 'my milestone';
    const labelName = ['first label', 'second label'];

    it('commits the SET_FILTERS mutation', () => {
      testAction(
        actions.setFilters,
        { milestone_title: milestoneTitle, label_name: labelName },
        state,
        [
          {
            type: types.SET_FILTERS,
            payload: { milestoneTitle, labelName },
          },
        ],
        [{ type: 'fetchMergeRequests' }],
      );
    });
  });

  describe('setPage', () => {
    it('commits SET_PAGE mutation', () => {
      testAction(actions.setPage, 2, state, [{ type: types.SET_PAGE, payload: 2 }], []);
    });
  });
});
