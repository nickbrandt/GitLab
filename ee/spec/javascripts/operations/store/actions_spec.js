import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import store from 'ee/operations/store/index';
import * as types from 'ee/operations/store/mutation_types';
import defaultActions, * as actions from 'ee/operations/store/actions';
import testAction from 'spec/helpers/vuex_action_helper';
import { clearState } from '../helpers';
import { mockText, mockProjectData } from '../mock_data';

describe('actions', () => {
  const mockAddEndpoint = 'mock-add_endpoint';
  const mockListEndpoint = 'mock-list_endpoint';
  const mockResponse = { data: 'mock-data' };
  const mockProjects = mockProjectData(1);
  const [mockOneProject] = mockProjects;
  let mockAxios;

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    clearState(store);
    mockAxios.restore();
  });

  describe('addProjectsToDashboard', () => {
    it('posts project token ids to project add endpoint', done => {
      store.state.projectEndpoints.add = mockAddEndpoint;
      store.state.projectTokens = mockProjects;

      mockAxios.onPost(mockAddEndpoint).replyOnce(200, mockResponse);

      testAction(
        actions.addProjectsToDashboard,
        null,
        store.state,
        [],
        [
          {
            type: 'requestAddProjectsToDashboardSuccess',
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
        [{ type: 'requestAddProjectsToDashboardError' }],
        done,
      );
    });
  });

  describe('clearInputValue', () => {
    it('sets inputValue to empty string', done => {
      testAction(
        actions.clearInputValue,
        null,
        store.state,
        [
          {
            type: types.SET_INPUT_VALUE,
            payload: '',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('clearProjectTokens', () => {
    it('sets project tokens to an empty array', done => {
      testAction(
        actions.clearProjectTokens,
        null,
        store.state,
        [
          {
            type: types.SET_PROJECT_TOKENS,
            payload: [],
          },
        ],
        [],
        done,
      );
    });
  });

  describe('filterProjectTokensById', () => {
    it('removes all project tokens except those with specified ids', done => {
      store.state.projectTokens = mockProjects;
      const ids = mockProjects.map(project => project.id);

      testAction(
        actions.filterProjectTokensById,
        ids,
        store.state,
        [
          {
            type: types.SET_PROJECT_TOKENS,
            payload: mockProjects,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestAddProjectsToDashboardSuccess', () => {
    it('fetches projects when new projects are added to the dashboard', done => {
      testAction(
        actions.requestAddProjectsToDashboardSuccess,
        {
          added: [1],
          invalid: [],
          duplicate: [],
        },
        store.state,
        [],
        [
          {
            type: 'clearInputValue',
          },
          {
            type: 'clearProjectTokens',
          },
          {
            type: 'fetchProjects',
          },
        ],
        done,
      );
    });

    it('removes projectTokens when user tries to add duplicates to dashboard', done => {
      testAction(
        actions.requestAddProjectsToDashboardSuccess,
        {
          added: [],
          invalid: [],
          duplicate: [1],
        },
        store.state,
        [],
        [
          {
            type: 'clearInputValue',
          },
          {
            type: 'clearProjectTokens',
          },
        ],
        done,
      );
    });

    it('does not remove projectTokens when user adds invalid projects to dashbaord', done => {
      testAction(
        actions.requestAddProjectsToDashboardSuccess,
        {
          added: [],
          invalid: [1],
          duplicate: [],
        },
        store.state,
        [],
        [
          {
            type: 'clearInputValue',
          },
          {
            type: 'filterProjectTokensById',
            payload: [1],
          },
        ],
        done,
      );
    });

    const errorMessage =
      'The Operations Dashboard is available for public projects, and private projects in groups with a Gold plan.';
    const addTokens = count => {
      for (let i = 0; i < count; i += 1) {
        store.dispatch('addProjectToken', {
          id: i,
          name: 'mock-name',
        });
      }
    };
    const addInvalidProjects = invalid =>
      store.dispatch('requestAddProjectsToDashboardSuccess', {
        added: [],
        invalid,
        duplicate: [],
      });

    it('displays an error when user tries to add one invalid project to dashboard', () => {
      const spy = spyOnDependency(defaultActions, 'createFlash');
      addTokens(1);
      addInvalidProjects([0]);

      expect(spy).toHaveBeenCalledWith(`Unable to add mock-name. ${errorMessage}`);
    });

    it('displays an error when user tries to add two invalid projects to dashboard', () => {
      const spy = spyOnDependency(defaultActions, 'createFlash');
      addTokens(2);
      addInvalidProjects([0, 1]);

      expect(spy).toHaveBeenCalledWith(`Unable to add mock-name and mock-name. ${errorMessage}`);
    });

    it('displays an error when user tries to add more than two invalid projects to dashboard', () => {
      const spy = spyOnDependency(defaultActions, 'createFlash');
      addTokens(3);
      addInvalidProjects([0, 1, 2]);

      expect(spy).toHaveBeenCalledWith(
        `Unable to add mock-name, mock-name, and mock-name. ${errorMessage}`,
      );
    });
  });

  describe('requestAddProjectsToDashboardError', () => {
    it('shows error message', () => {
      const spy = spyOnDependency(defaultActions, 'createFlash');
      store.dispatch('requestAddProjectsToDashboardError');

      expect(spy).toHaveBeenCalledWith(mockText.ADD_PROJECTS_ERROR);
    });
  });

  describe('addProjectToken', () => {
    it('adds project token to state', done => {
      testAction(
        actions.addProjectToken,
        mockOneProject,
        null,
        [
          {
            type: types.ADD_PROJECT_TOKEN,
            payload: mockOneProject,
          },
          {
            type: types.SET_INPUT_VALUE,
            payload: '',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('clearProjectSearchResults', () => {
    it('clears all project search results', done => {
      store.state.projectSearchResults = mockProjects;

      testAction(
        actions.clearProjectSearchResults,
        null,
        store.state,
        [
          {
            type: types.SET_PROJECT_SEARCH_RESULTS,
            payload: [],
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
        [
          { type: 'requestProjects' },
          { type: 'receiveProjectsSuccess' },
          { type: 'requestProjects' },
        ],
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
        [
          { type: 'requestProjects' },
          { type: 'receiveProjectsError' },
          { type: 'requestProjects' },
        ],
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
        [{ type: types.TOGGLE_IS_LOADING_PROJECTS }],
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
            type: types.SET_PROJECTS,
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
            type: types.SET_PROJECTS,
            payload: null,
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
        [{ type: 'requestRemoveProjectSuccess' }],
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
        [{ type: 'requestRemoveProjectError' }],
        done,
      );
    });
  });

  describe('requestRemoveProjectSuccess', () => {
    it('fetches operations dashboard projects', done => {
      testAction(
        actions.requestRemoveProjectSuccess,
        null,
        null,
        [],
        [{ type: 'fetchProjects' }],
        done,
      );
    });
  });

  describe('requestRemoveProjectError', () => {
    it('displays project removal error', done => {
      const spy = spyOnDependency(defaultActions, 'createFlash');

      testAction(actions.requestRemoveProjectError, null, null, [], [], done);

      expect(spy).toHaveBeenCalledWith(mockText.REMOVE_PROJECT_ERROR);
    });
  });

  describe('removeProjectToken', () => {
    it('removes project token', done => {
      store.state.projectTokens = mockProjects;
      const [{ id }] = store.state.projectTokens;

      testAction(
        actions.removeProjectTokenAt,
        id,
        store.state,
        [
          {
            type: types.REMOVE_PROJECT_TOKEN_AT,
            payload: 0,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('searchProjects', () => {
    const mockQuery = 'mock-query';

    it('sets project search results', done => {
      mockAxios.onAny().replyOnce(200, mockProjects);

      testAction(
        actions.searchProjects,
        mockQuery,
        store.state,
        [
          {
            type: types.INCREMENT_PROJECT_SEARCH_COUNT,
            payload: 1,
          },
          {
            type: types.SET_PROJECT_SEARCH_RESULTS,
            payload: mockProjects,
          },
          {
            type: types.DECREMENT_PROJECT_SEARCH_COUNT,
            payload: 1,
          },
        ],
        [],
        done,
      );
    });

    it('clears project search results on error', done => {
      mockAxios.onAny().replyOnce(500);

      testAction(
        actions.searchProjects,
        mockQuery,
        store.state,
        [
          {
            type: types.INCREMENT_PROJECT_SEARCH_COUNT,
            payload: 1,
          },
          {
            type: types.SET_PROJECT_SEARCH_RESULTS,
            payload: [],
          },
          {
            type: types.DECREMENT_PROJECT_SEARCH_COUNT,
            payload: 1,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setInputValue', () => {
    it('sets input value', done => {
      const mockValue = 'mock-value';

      testAction(
        actions.setInputValue,
        mockValue,
        null,
        [
          {
            type: types.SET_INPUT_VALUE,
            payload: mockValue,
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
