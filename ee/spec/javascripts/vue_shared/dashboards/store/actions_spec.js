import MockAdapter from 'axios-mock-adapter';
import createStore from 'ee/vue_shared/dashboards/store/index';
import * as types from 'ee/vue_shared/dashboards/store/mutation_types';
import defaultActions, * as actions from 'ee/vue_shared/dashboards/store/actions';
import testAction from 'spec/helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import clearState from '../helpers';
import { mockHeaders, mockText, mockProjectData } from '../mock_data';

describe('actions', () => {
  const mockAddEndpoint = 'mock-add_endpoint';
  const mockListEndpoint = 'mock-list_endpoint';
  const mockResponse = { data: 'mock-data' };
  const mockProjects = mockProjectData(1);
  const [mockOneProject] = mockProjects;
  let store;
  let mockAxios;

  beforeEach(() => {
    store = createStore();
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    clearState(store);
    mockAxios.restore();
    actions.clearProjectsEtagPoll();
  });

  describe('addProjectsToDashboard', () => {
    it('posts selected project ids to project add endpoint', done => {
      store.state.projectEndpoints.add = mockAddEndpoint;
      store.state.selectedProjects = mockProjects;

      mockAxios.onPost(mockAddEndpoint).replyOnce(200, mockResponse);

      testAction(
        actions.addProjectsToDashboard,
        null,
        store.state,
        [],
        [
          {
            type: 'receiveAddProjectsToDashboardSuccess',
            payload: mockResponse,
          },
        ],
        done,
      );
    });

    it('calls addProjectsToDashboard error handler on error', done => {
      mockAxios.onPost(mockAddEndpoint).replyOnce(500);

      testAction(
        actions.addProjectsToDashboard,
        null,
        store.state,
        [],
        [{ type: 'receiveAddProjectsToDashboardError' }],
        done,
      );
    });
  });

  describe('toggleSelectedProject', () => {
    it(`adds a project to selectedProjects if it doesn't already exist in the list`, done => {
      testAction(
        actions.toggleSelectedProject,
        mockOneProject,
        store.state,
        [
          {
            type: types.ADD_SELECTED_PROJECT,
            payload: mockOneProject,
          },
        ],
        [],
        done,
      );
    });

    it(`removes a project from selectedProjects if it already exist in the list`, done => {
      store.state.selectedProjects = mockProjects;

      testAction(
        actions.toggleSelectedProject,
        mockOneProject,
        store.state,
        [
          {
            type: types.REMOVE_SELECTED_PROJECT,
            payload: mockOneProject,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveAddProjectsToDashboardSuccess', () => {
    it('fetches projects when new projects are added to the dashboard', done => {
      testAction(
        actions.receiveAddProjectsToDashboardSuccess,
        {
          added: [1],
          invalid: [],
          duplicate: [],
        },
        store.state,
        [],
        [
          {
            type: 'forceProjectsRequest',
          },
        ],
        done,
      );
    });

    const errorMessage =
      'This dashboard is available for public projects, and private projects in groups with a Silver plan.';
    const selectProjects = count => {
      for (let i = 0; i < count; i += 1) {
        store.dispatch('toggleSelectedProject', {
          id: i,
          name: 'mock-name',
        });
      }
    };
    const addInvalidProjects = invalid =>
      store.dispatch('receiveAddProjectsToDashboardSuccess', {
        added: [],
        invalid,
        duplicate: [],
      });

    it('displays an error when user tries to add one invalid project to dashboard', () => {
      const spy = spyOnDependency(defaultActions, 'createFlash');
      selectProjects(1);
      addInvalidProjects([0]);

      expect(spy).toHaveBeenCalledWith(`Unable to add mock-name. ${errorMessage}`);
    });

    it('displays an error when user tries to add two invalid projects to dashboard', () => {
      const spy = spyOnDependency(defaultActions, 'createFlash');
      selectProjects(2);
      addInvalidProjects([0, 1]);

      expect(spy).toHaveBeenCalledWith(`Unable to add mock-name and mock-name. ${errorMessage}`);
    });

    it('displays an error when user tries to add more than two invalid projects to dashboard', () => {
      const spy = spyOnDependency(defaultActions, 'createFlash');
      selectProjects(3);
      addInvalidProjects([0, 1, 2]);

      expect(spy).toHaveBeenCalledWith(
        `Unable to add mock-name, mock-name, and mock-name. ${errorMessage}`,
      );
    });
  });

  describe('receiveAddProjectsToDashboardError', () => {
    it('shows error message', () => {
      const spy = spyOnDependency(defaultActions, 'createFlash');
      store.dispatch('receiveAddProjectsToDashboardError');

      expect(spy).toHaveBeenCalledWith(mockText.ADD_PROJECTS_ERROR);
    });
  });

  describe('clearSearchResults', () => {
    it('clears all project search results', done => {
      store.state.projectSearchResults = mockProjects;

      testAction(
        actions.clearSearchResults,
        null,
        store.state,
        [
          {
            type: types.CLEAR_SEARCH_RESULTS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchProjects', () => {
    it('calls project list endpoint', done => {
      store.state.projectEndpoints.list = mockListEndpoint;
      mockAxios.onGet(mockListEndpoint).replyOnce(200);

      testAction(
        actions.fetchProjects,
        null,
        store.state,
        [],
        [{ type: 'requestProjects' }, { type: 'receiveProjectsSuccess' }],
        done,
      );
    });

    it('handles response errors', done => {
      store.state.projectEndpoints.list = mockListEndpoint;
      mockAxios.onGet(mockListEndpoint).replyOnce(500);

      testAction(
        actions.fetchProjects,
        null,
        store.state,
        [],
        [{ type: 'requestProjects' }, { type: 'receiveProjectsError' }],
        done,
      );
    });
  });

  describe('requestProjects', () => {
    it('toggles project loading state', done => {
      testAction(
        actions.requestProjects,
        null,
        store.state,
        [{ type: types.REQUEST_PROJECTS }],
        [],
        done,
      );
    });
  });

  describe('receiveProjectsSuccess', () => {
    it('sets projects from data on success', done => {
      testAction(
        actions.receiveProjectsSuccess,
        { projects: mockProjects },
        store.state,
        [
          {
            type: types.RECEIVE_PROJECTS_SUCCESS,
            payload: mockProjects,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveProjectsError', () => {
    it('clears projects and alerts user of error', done => {
      const spy = spyOnDependency(defaultActions, 'createFlash');
      store.state.projects = mockProjects;

      testAction(
        actions.receiveProjectsError,
        null,
        store.state,
        [
          {
            type: types.RECEIVE_PROJECTS_ERROR,
          },
        ],
        [],
        done,
      );

      expect(spy).toHaveBeenCalledWith(mockText.RECEIVE_PROJECTS_ERROR);
    });
  });

  describe('removeProject', () => {
    const mockRemovePath = 'mock-removePath';

    it('calls project removal path and fetches projects on success', done => {
      mockAxios.onDelete(mockRemovePath).replyOnce(200);

      testAction(
        actions.removeProject,
        mockRemovePath,
        null,
        [],
        [{ type: 'receiveRemoveProjectSuccess' }],
        done,
      );
    });

    it('passes off handling of project removal errors', done => {
      mockAxios.onDelete(mockRemovePath).replyOnce(500);

      testAction(
        actions.removeProject,
        mockRemovePath,
        null,
        [],
        [{ type: 'receiveRemoveProjectError' }],
        done,
      );
    });
  });

  describe('receiveRemoveProjectSuccess', () => {
    it('fetches dashboard projects', done => {
      testAction(
        actions.receiveRemoveProjectSuccess,
        null,
        null,
        [],
        [{ type: 'forceProjectsRequest' }],
        done,
      );
    });
  });

  describe('receiveRemoveProjectError', () => {
    it('displays project removal error', done => {
      const spy = spyOnDependency(defaultActions, 'createFlash');

      testAction(actions.receiveRemoveProjectError, null, null, [], [], done);

      expect(spy).toHaveBeenCalledWith(mockText.REMOVE_PROJECT_ERROR);
    });
  });

  describe('fetchSearchResults', () => {
    it('dispatches minimumQueryMessage if the search query is falsy', done => {
      const searchQueries = [null, undefined, false, NaN];

      Promise.all(
        searchQueries.map(searchQuery => {
          store.state.searchQuery = searchQuery;

          return testAction(
            actions.fetchSearchResults,
            null,
            store.state,
            [],
            [
              {
                type: 'requestSearchResults',
              },
              {
                type: 'minimumQueryMessage',
              },
            ],
          );
        }),
      )
        .then(done)
        .catch(done.fail);
    });

    it('dispatches minimumQueryMessage if the search query was empty', done => {
      store.state.searchQuery = '';

      testAction(
        actions.fetchSearchResults,
        null,
        store.state,
        [],
        [
          {
            type: 'requestSearchResults',
          },
          {
            type: 'minimumQueryMessage',
          },
        ],
        done,
      );
    });

    it(`dispatches minimumQueryMessage if the search query wasn't long enough`, done => {
      store.state.searchQuery = 'a';

      testAction(
        actions.fetchSearchResults,
        null,
        store.state,
        [],
        [
          {
            type: 'requestSearchResults',
          },
          {
            type: 'minimumQueryMessage',
          },
        ],
        done,
      );
    });

    it(`dispatches the correct actions when the query is valid`, done => {
      mockAxios.onAny().reply(200, mockProjects, mockHeaders);
      store.state.searchQuery = 'mock-query';

      testAction(
        actions.fetchSearchResults,
        null,
        store.state,
        [],
        [
          {
            type: 'requestSearchResults',
          },
          {
            type: 'receiveSearchResultsSuccess',
            payload: { data: mockProjects, headers: mockHeaders },
          },
        ],
        done,
      );
    });
  });

  describe('fetchNextPage', () => {
    it(`fetches the next page`, done => {
      mockAxios.onAny().reply(200, mockProjects, mockHeaders);
      store.state.pageInfo = mockHeaders.pageInfo;
      testAction(
        actions.fetchNextPage,
        null,
        store.state,
        [],
        [
          {
            type: 'receiveNextPageSuccess',
            payload: { data: mockProjects, headers: mockHeaders },
          },
        ],
        done,
      );
    });

    it(`stops fetching if current page is the last page`, done => {
      mockAxios.onAny().reply(200, mockProjects, mockHeaders);
      store.state.pageInfo.totalPages = 3;
      store.state.pageInfo.currentPage = 3;
      testAction(actions.fetchNextPage, mockHeaders, store.state, [], [], done);
    });
  });

  describe('requestSearchResults', () => {
    it(`commits the REQUEST_SEARCH_RESULTS mutation`, done => {
      testAction(
        actions.requestSearchResults,
        null,
        store.state,
        [
          {
            type: types.REQUEST_SEARCH_RESULTS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveNextPageSuccess', () => {
    it(`commits the RECEIVE_NEXT_PAGE_SUCCESS mutation`, done => {
      testAction(
        actions.receiveNextPageSuccess,
        mockHeaders,
        store.state,
        [
          {
            type: types.RECEIVE_NEXT_PAGE_SUCCESS,
            payload: mockHeaders,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveSearchResultsSuccess', () => {
    it('commits the RECEIVE_SEARCH_RESULTS_SUCCESS mutation', done => {
      testAction(
        actions.receiveSearchResultsSuccess,
        mockProjects,
        store.state,
        [
          {
            type: types.RECEIVE_SEARCH_RESULTS_SUCCESS,
            payload: mockProjects,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveSearchResultsError', () => {
    it('commits the RECEIVE_SEARCH_RESULTS_ERROR mutation', done => {
      testAction(
        actions.receiveSearchResultsError,
        ['error'],
        store.state,
        [
          {
            type: types.RECEIVE_SEARCH_RESULTS_ERROR,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setProjectEndpoints', () => {
    it('commits project list and add endpoints', done => {
      testAction(
        actions.setProjectEndpoints,
        {
          add: mockAddEndpoint,
          list: mockListEndpoint,
        },
        store.state,
        [
          {
            type: types.SET_PROJECT_ENDPOINT_LIST,
            payload: mockListEndpoint,
          },
          {
            type: types.SET_PROJECT_ENDPOINT_ADD,
            payload: mockAddEndpoint,
          },
        ],
        [],
        done,
      );
    });
  });
});
