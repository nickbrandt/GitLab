import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'spec/helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';
import actionsModule, * as actions from 'ee/dependencies/store/actions';
import getInitialState from 'ee/dependencies/store/state';
import { FETCH_ERROR_MESSAGE } from 'ee/dependencies/store/constants';

describe('Dependencies actions', () => {
  /**
   * This file only contains tests for failure conditions. Tests for success
   * conditions are in `ee/spec/frontend/dependencies/store/actions_spec.js`.
   * The split is due to https://gitlab.com/gitlab-org/gitlab-ce/issues/63225.
   */
  describe('fetchDependenciesPagination', () => {
    const failureScenarios = [
      {
        context: 'an invalid response',
        endpoint: TEST_HOST,
        responseDetails: [200, { foo: 'bar' }],
      },
      {
        context: 'a response error',
        endpoint: TEST_HOST,
        responseDetails: [500],
      },
      {
        context: 'no endpoint',
        endpoint: '',
        responseDetails: [],
      },
    ];

    failureScenarios.forEach(({ context, endpoint, responseDetails }) => {
      describe(`given ${context}`, () => {
        let state;
        let flashSpy;
        let mock;

        beforeEach(() => {
          mock = new MockAdapter(axios);
          state = getInitialState();
          flashSpy = spyOnDependency(actionsModule, 'createFlash');
          state.endpoint = endpoint;
          if (endpoint) {
            mock.onGet(state.endpoint).replyOnce(...responseDetails);
          }
        });

        afterEach(() => {
          mock.restore();
        });

        it('dispatches the correct actions and creates a flash', done => {
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
                type: 'receiveDependenciesPaginationError',
                payload: jasmine.any(Error),
              },
            ],
          )
            .then(done.fail)
            .catch(() => {
              expect(flashSpy).toHaveBeenCalledTimes(1);
              expect(flashSpy).toHaveBeenCalledWith(FETCH_ERROR_MESSAGE);
              done();
            });
        });
      });
    });
  });
});
