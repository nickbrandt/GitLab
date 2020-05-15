import testAction from 'helpers/vuex_action_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createState from 'ee/security_dashboard/store/modules/project_selector/state';
import { vuexApolloClient } from 'ee/security_dashboard/graphql/provider';
import * as types from 'ee/security_dashboard/store/modules/project_selector/mutation_types';
import * as actions from 'ee/security_dashboard/store/modules/project_selector/actions';
import createFlash from '~/flash';

jest.mock('~/flash');

describe('EE projectSelector actions', () => {
  const getMockProjects = n => [...Array(n).keys()].map(i => ({ id: i, name: `project-${i}` }));

  const mockResponse = { data: 'mock-data' };

  let mockDispatchContext;
  let state;

  const pageInfo = {
    hasNextPage: true,
    endCursor: '',
  };

  beforeEach(() => {
    mockDispatchContext = { dispatch: () => {}, commit: () => {}, state };
    state = createState();
  });

  describe('toggleSelectedProject', () => {
    it('adds a project to selectedProjects if it does not already exist in the list', done => {
      const payload = getMockProjects(1);

      testAction(
        actions.toggleSelectedProject,
        payload,
        state,
        [
          {
            type: types.SELECT_PROJECT,
            payload,
          },
        ],
        [],
        done,
      );
    });

    it('removes a project from selectedProjects if it already exist in the list', () => {
      const payload = getMockProjects(1)[0];
      state.selectedProjects = getMockProjects(1);

      return testAction(
        actions.toggleSelectedProject,
        payload,
        state,
        [
          {
            type: types.DESELECT_PROJECT,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe('addProjects', () => {
    it(`makes the GraphQL mutation with the selected project's ids`, () => {
      const projectIds = ['1', '2'];

      state.selectedProjects = [{ id: projectIds[0], name: '1' }, { id: projectIds[1], name: '2' }];

      const spy = jest.spyOn(vuexApolloClient, 'mutate').mockResolvedValue({
        data: { addProjectToSecurityDashboard: { project: {} } },
      });

      actions.addProjects({ state, dispatch: () => {} });

      return waitForPromises().then(() => {
        expect(spy).toHaveBeenCalled();
      });
    });

    it('dispatches the correct actions when the request is successful', () => {
      const projectIds = ['1'];
      const project = { id: projectIds[0], name: '1' };

      state.selectedProjects = [project];

      jest
        .spyOn(vuexApolloClient, 'mutate')
        .mockResolvedValue({ data: { addProjectToSecurityDashboard: { project } } });

      return testAction(
        actions.addProjects,
        null,
        state,
        [],
        [
          { type: 'requestAddProjects' },
          {
            type: 'receiveAddProjectsSuccess',
            payload: { added: [project], invalid: [] },
          },
          { type: 'clearSearchResults' },
        ],
      );
    });

    it('calls addProjects error handler on error', () => {
      const projectIds = ['1', '2'];

      state.selectedProjects = [{ id: projectIds[0], name: '1' }];

      jest.spyOn(vuexApolloClient, 'mutate').mockRejectedValue(new Error('new error'));

      return testAction(
        actions.addProjects,
        null,
        state,
        [],
        [
          { type: 'requestAddProjects' },
          { type: 'receiveAddProjectsError' },
          {
            type: 'receiveAddProjectsSuccess',
            payload: { added: [], invalid: ['1'] },
          },
          { type: 'clearSearchResults' },
        ],
      );
    });
  });

  describe('requestAddProjects', () => {
    it('commits the REQUEST_ADD_PROJECTS mutation', () =>
      testAction(
        actions.requestAddProjects,
        null,
        state,
        [
          {
            type: types.REQUEST_ADD_PROJECTS,
          },
        ],
        [],
      ));
  });

  describe('receiveAddProjectsSuccess', () => {
    beforeEach(() => {
      state.selectedProjects = getMockProjects(3);
    });

    it('fetches projects when new projects are added to the dashboard', () => {
      const addedProject = state.selectedProjects[0];
      const payload = {
        added: [addedProject.id],
        invalid: [],
        duplicate: [],
      };

      return testAction(
        actions.receiveAddProjectsSuccess,
        payload,
        state,
        [{ type: types.RECEIVE_ADD_PROJECTS_SUCCESS }],
        [
          {
            type: 'fetchProjects',
          },
        ],
      );
    });

    it('displays an error when user tries to add one invalid project to dashboard', () => {
      const invalidProject = state.selectedProjects[0];
      const payload = {
        added: [],
        invalid: [invalidProject.id],
      };

      return testAction(
        actions.receiveAddProjectsSuccess,
        payload,
        state,
        [{ type: types.RECEIVE_ADD_PROJECTS_SUCCESS }],
        [],
      ).then(() => {
        expect(createFlash).toHaveBeenCalledWith(`Unable to add ${invalidProject.name}`);
      });
    });

    it('displays an error when user tries to add two invalid projects to dashboard', () => {
      const invalidProject1 = state.selectedProjects[0];
      const invalidProject2 = state.selectedProjects[1];
      const payload = {
        added: [],
        invalid: [invalidProject1.id, invalidProject2.id],
      };

      return testAction(
        actions.receiveAddProjectsSuccess,
        payload,
        state,
        [{ type: types.RECEIVE_ADD_PROJECTS_SUCCESS }],
        [],
      ).then(() => {
        expect(createFlash).toHaveBeenCalledWith(
          `Unable to add ${invalidProject1.name} and ${invalidProject2.name}`,
        );
      });
    });

    it('displays an error when user tries to add more than two invalid projects to dashboard', () => {
      const invalidProject1 = state.selectedProjects[0];
      const invalidProject2 = state.selectedProjects[1];
      const invalidProject3 = state.selectedProjects[2];
      const payload = {
        added: [],
        invalid: [invalidProject1.id, invalidProject2.id, invalidProject3.id],
      };

      return testAction(
        actions.receiveAddProjectsSuccess,
        payload,
        state,
        [{ type: types.RECEIVE_ADD_PROJECTS_SUCCESS }],
        [],
      ).then(() => {
        expect(createFlash).toHaveBeenCalledWith(
          `Unable to add ${invalidProject1.name}, ${invalidProject2.name}, and ${invalidProject3.name}`,
        );
      });
    });
  });

  describe('receiveAddProjectsError', () => {
    it('commits RECEIVE_ADD_PROJECTS_ERROR', () =>
      testAction(
        actions.receiveAddProjectsError,
        null,
        state,
        [
          {
            type: types.RECEIVE_ADD_PROJECTS_ERROR,
          },
        ],
        [],
      ));

    it('shows error message', () => {
      actions.receiveAddProjectsError(mockDispatchContext);

      expect(createFlash).toHaveBeenCalledTimes(1);
      expect(createFlash).toHaveBeenCalledWith(
        'Something went wrong, unable to add projects to dashboard',
      );
    });
  });

  describe('clearSearchResults', () => {
    it('clears all project search results', () =>
      testAction(
        actions.clearSearchResults,
        null,
        state,
        [
          {
            type: types.CLEAR_SEARCH_RESULTS,
          },
        ],
        [],
      ));
  });

  describe('fetchProjects', () => {
    it('calls project query', () => {
      jest.spyOn(vuexApolloClient, 'query').mockResolvedValue({
        data: { instanceSecurityDashboard: { projects: { nodes: mockResponse } } },
      });

      return testAction(
        actions.fetchProjects,
        null,
        state,
        [],
        [
          { type: 'requestProjects' },
          { type: 'receiveProjectsSuccess', payload: { projects: mockResponse } },
        ],
      );
    });

    it('handles response errors', () => {
      jest.spyOn(vuexApolloClient, 'query').mockReturnValue(Promise.reject());

      return testAction(
        actions.fetchProjects,
        null,
        state,
        [],
        [{ type: 'requestProjects' }, { type: 'receiveProjectsError' }],
      );
    });
  });

  describe('requestProjects', () => {
    it('toggles project loading state', () =>
      testAction(actions.requestProjects, null, state, [{ type: types.REQUEST_PROJECTS }], []));
  });

  describe('receiveProjectsSuccess', () => {
    it('sets projects from data on success', () => {
      const payload = {
        projects: [{ id: 0, name: 'mock-name1' }],
      };

      return testAction(
        actions.receiveProjectsSuccess,
        payload,
        state,
        [
          {
            type: types.RECEIVE_PROJECTS_SUCCESS,
            payload: payload.projects,
          },
        ],
        [],
      );
    });
  });

  describe('receiveProjectsError', () => {
    it('clears projects and alerts user of error', () =>
      testAction(
        actions.receiveProjectsError,
        null,
        state,
        [
          {
            type: types.RECEIVE_PROJECTS_ERROR,
          },
        ],
        [],
      ).then(() => {
        expect(createFlash).toHaveBeenCalledWith('Something went wrong, unable to get projects');
      }));
  });

  describe('removeProject', () => {
    const mockRemovePath = 'mock-removePath';

    it('calls project removal path and fetches projects on success', () => {
      jest.spyOn(vuexApolloClient, 'mutate').mockResolvedValue({
        data: mockResponse,
      });

      return testAction(
        actions.removeProject,
        mockRemovePath,
        null,
        [],
        [{ type: 'requestRemoveProject' }, { type: 'receiveRemoveProjectSuccess' }],
      );
    });

    it('passes off handling of project removal errors', () => {
      jest.spyOn(vuexApolloClient, 'mutate').mockReturnValue(Promise.reject());

      return testAction(
        actions.removeProject,
        mockRemovePath,
        null,
        [],
        [{ type: 'requestRemoveProject' }, { type: 'receiveRemoveProjectError' }],
      );
    });
  });

  describe('requestRemoveProject', () => {
    it('commits REQUEST_REMOVE_PROJECT mutation', () =>
      testAction(
        actions.requestRemoveProject,
        null,
        state,
        [
          {
            type: types.REQUEST_REMOVE_PROJECT,
          },
        ],
        [],
      ));
  });

  describe('receiveRemoveProjectSuccess', () => {
    it('commits RECEIVE_REMOVE_PROJECT_SUCCESS mutation and dispatches fetchProjects', () =>
      testAction(
        actions.receiveRemoveProjectSuccess,
        null,
        state,
        [
          {
            type: types.RECEIVE_REMOVE_PROJECT_SUCCESS,
          },
        ],
        [{ type: 'fetchProjects' }],
      ));
  });

  describe('receiveRemoveProjectError', () => {
    it('commits REQUEST_REMOVE_PROJECT mutation', () =>
      testAction(
        actions.receiveRemoveProjectError,
        null,
        state,
        [
          {
            type: types.RECEIVE_REMOVE_PROJECT_ERROR,
          },
        ],
        [],
      ));

    it('displays project removal error', () => {
      actions.receiveRemoveProjectError(mockDispatchContext);

      expect(createFlash).toHaveBeenCalledTimes(1);
      expect(createFlash).toHaveBeenCalledWith('Something went wrong, unable to remove project');
    });
  });

  describe('setSearchQuery', () => {
    it('commits the REQUEST_SEARCH_RESULTS mutation', () => {
      const payload = 'search-query';

      return testAction(
        actions.setSearchQuery,
        payload,
        state,
        [
          {
            type: types.SET_SEARCH_QUERY,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe('fetchSearchResults', () => {
    it.each([null, undefined, false, NaN, 0, ''])(
      'dispatches setMinimumQueryMessage if the search query is falsy',
      searchQuery => {
        state.searchQuery = searchQuery;

        return testAction(
          actions.fetchSearchResults,
          null,
          state,
          [],
          [
            {
              type: 'requestSearchResults',
            },
            {
              type: 'setMinimumQueryMessage',
            },
          ],
        );
      },
    );

    it.each(['a', 'aa'])(
      'dispatches setMinimumQueryMessage if the search query was not long enough',
      shortSearchQuery => {
        state.searchQuery = shortSearchQuery;

        return testAction(
          actions.fetchSearchResults,
          null,
          state,
          [],
          [
            {
              type: 'requestSearchResults',
            },
            {
              type: 'setMinimumQueryMessage',
            },
          ],
        );
      },
    );

    it('dispatches the correct actions when the query is valid', () => {
      const projects = [{ id: 0, name: 'mock-name1' }];

      jest.spyOn(vuexApolloClient, 'query').mockResolvedValue({
        data: { projects: { nodes: projects, pageInfo } },
      });
      state.searchQuery = 'mock-query';

      return testAction(
        actions.fetchSearchResults,
        null,
        state,
        [
          {
            type: types.RECEIVE_SEARCH_RESULTS_SUCCESS,
            payload: { data: projects, pageInfo },
          },
        ],
        [
          {
            type: 'requestSearchResults',
          },
        ],
      );
    });

    it('dispatches the correct actions when the request is not successful', () => {
      jest.spyOn(vuexApolloClient, 'query').mockReturnValue(Promise.reject());

      state.searchQuery = 'mock-query';

      testAction(
        actions.fetchSearchResults,
        null,
        state,
        [],
        [
          {
            type: 'requestSearchResults',
          },
          {
            type: 'receiveSearchResultsError',
          },
        ],
      );
    });
  });

  describe('requestSearchResults', () => {
    it('commits the REQUEST_SEARCH_RESULTS mutation', () =>
      testAction(
        actions.requestSearchResults,
        null,
        state,
        [
          {
            type: types.REQUEST_SEARCH_RESULTS,
          },
        ],
        [],
      ));
  });

  describe('receiveSearchResultsError', () => {
    it('commits the RECEIVE_SEARCH_RESULTS_ERROR mutation', () =>
      testAction(
        actions.receiveSearchResultsError,
        ['error'],
        state,
        [
          {
            type: types.RECEIVE_SEARCH_RESULTS_ERROR,
          },
        ],
        [],
      ));
  });

  describe('fetchSearchResultsNextPage', () => {
    describe('when there is a next page', () => {
      beforeEach(() => {
        state.pageInfo.hasNextPage = true;
        state.pageInfo.endCursor = 'abc';
      });

      it('dispatches the "receiveNextPageSuccess" action if the request is successful', () => {
        const projects = [{ id: 0, name: 'mock-name1' }];

        jest.spyOn(vuexApolloClient, 'query').mockResolvedValue({
          data: { projects: { nodes: projects, pageInfo } },
        });

        return testAction(
          actions.fetchSearchResultsNextPage,
          null,
          state,
          [
            {
              type: types.RECEIVE_NEXT_PAGE_SUCCESS,
              payload: { data: projects, pageInfo },
            },
          ],
          [],
        );
      });

      it('dispatches the "receiveSearchResultsError" action if the request is not successful', () => {
        jest.spyOn(vuexApolloClient, 'query').mockReturnValue(Promise.reject());

        return testAction(
          actions.fetchSearchResultsNextPage,
          null,
          state,
          [],
          [
            {
              type: 'receiveSearchResultsError',
            },
          ],
        );
      });
    });

    describe('when there is not a next page', () => {
      it('does not commit any mutations or dispatch any actions', () => {
        state.pageInfo.hasNextPage = false;

        return testAction(actions.fetchSearchResultsNextPage, [], state);
      });
    });
  });

  describe('setMinimumQueryMessage', () => {
    it('commits the SET_MINIMUM_QUERY_MESSAGE mutation', () =>
      testAction(
        actions.setMinimumQueryMessage,
        null,
        state,
        [
          {
            type: types.SET_MINIMUM_QUERY_MESSAGE,
          },
        ],
        [],
      ));
  });
});
