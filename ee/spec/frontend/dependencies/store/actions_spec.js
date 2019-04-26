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

import mockDependencies from './data/mock_dependencies';

jest.mock('~/flash', () => jest.fn());

describe('Dependencies actions', () => {
  const pageInfo = {
    page: 1,
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

  describe('setDependenciesDownloadEndpoint', () => {
    it('commits the correct mutation', done => {
      testAction(
        actions.setDependenciesDownloadEndpoint,
        TEST_HOST,
        getInitialState(),
        [
          {
            type: types.SET_DEPENDENCIES_DOWNLOAD_ENDPOINT,
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
    describe('given an array of dependencies', () => {
      it('commits the RECEIVE_DEPENDENCIES_SUCCESS mutation', done => {
        testAction(
          actions.receiveDependenciesSuccess,
          { headers, data: mockDependencies },
          getInitialState(),
          [
            {
              type: types.RECEIVE_DEPENDENCIES_SUCCESS,
              payload: { pageInfo, dependencies: mockDependencies },
            },
          ],
          [],
          done,
        );
      });
    });

    describe('given a report_status response', () => {
      it('commits the SET_REPORT_STATUS mutation', done => {
        const response = { report_status: 'file_not_found' };

        testAction(
          actions.receiveDependenciesSuccess,
          { data: response },
          getInitialState(),
          [
            {
              type: types.SET_REPORT_STATUS,
              payload: response.report_status,
            },
          ],
          [],
          done,
        );
      });
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
    const dependenciesTypeDescending = _.sortBy(mockDependencies, 'type').reverse();
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

    describe('on success', () => {
      describe('given no params', () => {
        beforeEach(() => {
          const sortParamsDefault = {
            sort_by: state.sortField,
            sort: state.sortOrder,
          };

          mock
            .onGet(state.endpoint, { params: sortParamsDefault })
            .replyOnce(200, mockDependencies, headers);
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
                payload: expect.objectContaining({ data: mockDependencies, headers }),
              },
            ],
            done,
          );
        });
      });

      describe('given sorting params', () => {
        const sortParamsTypeDescending = { sort_by: 'type', sort: SORT_ORDER.descending };

        beforeEach(() => {
          mock
            .onGet(state.endpoint, { params: sortParamsTypeDescending })
            .replyOnce(200, dependenciesTypeDescending, headers);
        });

        it('overrides default sorting params', done => {
          testAction(
            actions.fetchDependencies,
            sortParamsTypeDescending,
            state,
            [],
            [
              {
                type: 'requestDependencies',
              },
              {
                type: 'receiveDependenciesSuccess',
                payload: expect.objectContaining({ data: dependenciesTypeDescending, headers }),
              },
            ],
            done,
          );
        });
      });

      describe('a response with report_status', () => {
        const fileNotFoundResponse = { report_status: 'file_not_found' };

        beforeEach(() => {
          mock.onGet(state.endpoint).replyOnce(200, fileNotFoundResponse);
        });

        it('dispatches the receiveDependenciesSuccess action', done => {
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
                payload: expect.objectContaining({ data: fileNotFoundResponse }),
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
      const field = 'type';

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
          },
        ],
        done,
      );
    });
  });
});
