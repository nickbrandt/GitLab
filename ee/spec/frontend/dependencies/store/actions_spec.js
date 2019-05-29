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
    it('commits the correct mutation', done => {
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
        done,
      );
    });
  });

  describe('requestDependencies', () => {
    it('commits the correct mutation', done => {
      testAction(
        actions.requestDependencies,
        undefined,
        getInitialState(),
        [
          {
            type: types.REQUEST_DEPENDENCIES,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDependenciesSuccess', () => {
    it('commits the RECEIVE_DEPENDENCIES_SUCCESS mutation', done => {
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
        done,
      );
    });
  });

  describe('receiveDependenciesError', () => {
    it('commits the correct mutation', done => {
      const error = { error: true };

      testAction(
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
        done,
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

      it('does nothing', done => {
        testAction(actions.fetchDependencies, undefined, state, [], [], done);
      });
    });

    describe('on success', () => {
      describe('given no params', () => {
        beforeEach(() => {
          state.pageInfo = { ...pageInfo };

          const paramsDefault = {
            sort_by: state.sortField,
            sort: state.sortOrder,
            page: state.pageInfo.page,
          };

          mock
            .onGet(state.endpoint, { params: paramsDefault })
            .replyOnce(200, mockDependenciesResponse, headers);
        });

        it('uses default sorting params from state', done => {
          testAction(
            actions.fetchDependencies,
            undefined,
            state,
            [],
            [
              {
                type: 'requestDependencies',
              },
              {
                type: 'receiveDependenciesSuccess',
                payload: expect.objectContaining({ data: mockDependenciesResponse, headers }),
              },
            ],
            done,
          );
        });
      });

      describe('given params', () => {
        const paramsGiven = { sort_by: 'packager', sort: SORT_ORDER.descending, page: 4 };

        beforeEach(() => {
          mock
            .onGet(state.endpoint, { params: paramsGiven })
            .replyOnce(200, dependenciesPackagerDescending, headers);
        });

        it('overrides default params', done => {
          testAction(
            actions.fetchDependencies,
            paramsGiven,
            state,
            [],
            [
              {
                type: 'requestDependencies',
              },
              {
                type: 'receiveDependenciesSuccess',
                payload: expect.objectContaining({ data: dependenciesPackagerDescending, headers }),
              },
            ],
            done,
          );
        });
      });

      describe('an invalid response', () => {
        const nonsense = { foo: 'bar' };

        beforeEach(() => {
          mock.onGet(state.endpoint).replyOnce(200, nonsense);
        });

        it('dispatches the receiveDependenciesError action', done => {
          testAction(
            actions.fetchDependencies,
            undefined,
            state,
            [],
            [
              {
                type: 'requestDependencies',
              },
              {
                type: 'receiveDependenciesError',
                payload: expect.any(Error),
              },
            ],
            done,
          );
        });
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onGet(state.endpoint).reply(500);
      });

      it('dispatches the receiveDependenciesError action and creates a flash', done => {
        testAction(
          actions.fetchDependencies,
          undefined,
          state,
          [],
          [
            {
              type: 'requestDependencies',
            },
            {
              type: 'receiveDependenciesError',
              payload: expect.any(Error),
            },
          ],
          () => {
            expect(createFlash).toHaveBeenCalledTimes(1);
            expect(createFlash).toHaveBeenCalledWith(FETCH_ERROR_MESSAGE);
            done();
          },
        );
      });
    });
  });

  describe('setSortField', () => {
    it('commits the SET_SORT_FIELD mutation and dispatch the fetchDependencies action', done => {
      const field = 'packager';

      testAction(
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
        done,
      );
    });
  });

  describe('toggleSortOrder', () => {
    it('commits the TOGGLE_SORT_ORDER mutation and dispatch the fetchDependencies action', done => {
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
        done,
      );
    });
  });
});
