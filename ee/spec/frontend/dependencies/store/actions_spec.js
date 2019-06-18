import _ from 'underscore';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'helpers/test_constants';
import * as actions from 'ee/dependencies/store/actions';
import * as types from 'ee/dependencies/store/mutation_types';
import getInitialState from 'ee/dependencies/store/state';
import { SORT_ORDER, FETCH_ERROR_MESSAGE } from 'ee/dependencies/store/constants';
import createFlash from '~/flash';

import mockDependenciesResponse from './data/mock_dependencies';

jest.mock('~/flash', () => jest.fn());

describe('Dependencies actions', () => {
  const pageInfo = {
    page: 3,
    nextPage: 2,
    previousPage: 1,
    perPage: 20,
    total: 100,
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

  afterEach(() => {
    createFlash.mockClear();
  });

  describe('setDependenciesEndpoint', () => {
    it('commits the SET_DEPENDENCIES_ENDPOINT mutation', () =>
      testAction(
        actions.setDependenciesEndpoint,
        TEST_HOST,
        getInitialState(),
        [
          {
            type: types.SET_DEPENDENCIES_ENDPOINT,
            payload: TEST_HOST,
          },
        ],
        [],
      ));
  });

  describe('requestDependenciesPagination', () => {
    it('commits the REQUEST_DEPENDENCIES_PAGINATION mutation', () =>
      testAction(
        actions.requestDependenciesPagination,
        undefined,
        getInitialState(),
        [
          {
            type: types.REQUEST_DEPENDENCIES_PAGINATION,
          },
        ],
        [],
      ));
  });

  describe('receiveDependenciesPaginationSuccess', () => {
    const total = 123;
    it('commits the RECEIVE_DEPENDENCIES_PAGINATION_SUCCESS mutation', () =>
      testAction(
        actions.receiveDependenciesPaginationSuccess,
        total,
        getInitialState(),
        [
          {
            type: types.RECEIVE_DEPENDENCIES_PAGINATION_SUCCESS,
            payload: total,
          },
        ],
        [],
      ));
  });

  describe('receiveDependenciesPaginationError', () => {
    it('commits the RECEIVE_DEPENDENCIES_PAGINATION_ERROR mutation', () =>
      testAction(
        actions.receiveDependenciesPaginationError,
        undefined,
        getInitialState(),
        [
          {
            type: types.RECEIVE_DEPENDENCIES_PAGINATION_ERROR,
          },
        ],
        [],
      ));
  });

  describe('fetchDependenciesPagination', () => {
    let mock;
    let state;

    beforeEach(() => {
      state = getInitialState();
      state.endpoint = `${TEST_HOST}/dependencies`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock.onGet(state.endpoint).replyOnce(200, mockDependenciesResponse);
      });

      it('dispatches the correct actions', () =>
        testAction(
          actions.fetchDependenciesPagination,
          undefined,
          state,
          [],
          [
            {
              type: 'requestDependenciesPagination',
            },
            {
              type: 'receiveDependenciesPaginationSuccess',
              payload: mockDependenciesResponse.dependencies.length,
            },
          ],
        ));
    });

    /**
     * Tests for error conditions are in
     * `ee/spec/javascripts/dependencies/store/actions_spec.js`. They cannot be
     * tested here due to https://gitlab.com/gitlab-org/gitlab-ce/issues/63225.
     */
  });

  describe('requestDependencies', () => {
    const page = 4;
    it('commits the REQUEST_DEPENDENCIES mutation', () =>
      testAction(
        actions.requestDependencies,
        { page },
        getInitialState(),
        [
          {
            type: types.REQUEST_DEPENDENCIES,
            payload: { page },
          },
        ],
        [],
      ));
  });

  describe('receiveDependenciesSuccess', () => {
    it('commits the RECEIVE_DEPENDENCIES_SUCCESS mutation', () =>
      testAction(
        actions.receiveDependenciesSuccess,
        { headers, data: mockDependenciesResponse },
        getInitialState(),
        [
          {
            type: types.RECEIVE_DEPENDENCIES_SUCCESS,
            payload: {
              dependencies: mockDependenciesResponse.dependencies,
              reportInfo: mockDependenciesResponse.report,
              pageInfo,
            },
          },
        ],
        [],
      ));
  });

  describe('receiveDependenciesError', () => {
    it('commits the RECEIVE_DEPENDENCIES_ERROR mutation', () => {
      const error = { error: true };

      return testAction(
        actions.receiveDependenciesError,
        error,
        getInitialState(),
        [
          {
            type: types.RECEIVE_DEPENDENCIES_ERROR,
            payload: error,
          },
        ],
        [],
      );
    });
  });

  describe('fetchDependencies', () => {
    const dependenciesPackagerDescending = {
      ...mockDependenciesResponse,
      dependencies: _.sortBy(mockDependenciesResponse.dependencies, 'packager').reverse(),
    };
    let state;
    let mock;

    beforeEach(() => {
      state = getInitialState();
      state.endpoint = `${TEST_HOST}/dependencies`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('when endpoint is empty', () => {
      beforeEach(() => {
        state.endpoint = '';
      });

      it('does nothing', () => testAction(actions.fetchDependencies, undefined, state, [], []));
    });

    describe('on success', () => {
      describe('given no params', () => {
        let paramsDefault;
        beforeEach(() => {
          state.pageInfo = { ...pageInfo };

          paramsDefault = {
            sort_by: state.sortField,
            sort: state.sortOrder,
            page: state.pageInfo.page,
          };

          mock
            .onGet(state.endpoint, { params: paramsDefault })
            .replyOnce(200, mockDependenciesResponse, headers);
        });

        it('uses default sorting params from state', () =>
          testAction(
            actions.fetchDependencies,
            undefined,
            state,
            [],
            [
              {
                type: 'requestDependencies',
                payload: { page: paramsDefault.page },
              },
              {
                type: 'receiveDependenciesSuccess',
                payload: expect.objectContaining({ data: mockDependenciesResponse, headers }),
              },
            ],
          ));
      });

      describe('given params', () => {
        const paramsGiven = { sort_by: 'packager', sort: SORT_ORDER.descending, page: 4 };

        beforeEach(() => {
          mock
            .onGet(state.endpoint, { params: paramsGiven })
            .replyOnce(200, dependenciesPackagerDescending, headers);
        });

        it('overrides default params', () =>
          testAction(
            actions.fetchDependencies,
            paramsGiven,
            state,
            [],
            [
              {
                type: 'requestDependencies',
                payload: { page: paramsGiven.page },
              },
              {
                type: 'receiveDependenciesSuccess',
                payload: expect.objectContaining({ data: dependenciesPackagerDescending, headers }),
              },
            ],
          ));
      });
    });

    describe.each`
      responseType             | responseDetails
      ${'an invalid response'} | ${[200, { foo: 'bar' }]}
      ${'a response error'}    | ${[500]}
    `('given $responseType', ({ responseDetails }) => {
      let page;
      beforeEach(() => {
        ({ page } = state.pageInfo);
        mock.onGet(state.endpoint).replyOnce(...responseDetails);
      });

      it('dispatches the receiveDependenciesError action and creates a flash', () =>
        testAction(
          actions.fetchDependencies,
          undefined,
          state,
          [],
          [
            {
              type: 'requestDependencies',
              payload: { page },
            },
            {
              type: 'receiveDependenciesError',
              payload: expect.any(Error),
            },
          ],
        ).then(() => {
          expect(createFlash).toHaveBeenCalledTimes(1);
          expect(createFlash).toHaveBeenCalledWith(FETCH_ERROR_MESSAGE);
        }));
    });
  });

  describe('setSortField', () => {
    it('commits the SET_SORT_FIELD mutation and dispatch the fetchDependencies action', () => {
      const field = 'packager';

      return testAction(
        actions.setSortField,
        field,
        getInitialState(),
        [
          {
            type: types.SET_SORT_FIELD,
            payload: field,
          },
        ],
        [
          {
            type: 'fetchDependencies',
            payload: { page: 1 },
          },
        ],
      );
    });
  });

  describe('toggleSortOrder', () => {
    it('commits the TOGGLE_SORT_ORDER mutation and dispatch the fetchDependencies action', () =>
      testAction(
        actions.toggleSortOrder,
        undefined,
        getInitialState(),
        [
          {
            type: types.TOGGLE_SORT_ORDER,
          },
        ],
        [
          {
            type: 'fetchDependencies',
            payload: { page: 1 },
          },
        ],
      ));
  });
});
