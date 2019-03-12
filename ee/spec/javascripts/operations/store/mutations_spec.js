import state from 'ee/operations/store/state';
import mutations from 'ee/operations/store/mutations';
import * as types from 'ee/operations/store/mutation_types';
import { mockProjectData } from '../mock_data';

describe('mutations', () => {
  const projects = mockProjectData(3);
  const mockEndpoint = 'https://mock-endpoint';
  const mockSearches = new Array(5).fill(null);
  let localState;

  beforeEach(() => {
    localState = state();
  });

  describe('DECREMENT_PROJECT_SEARCH_COUNT', () => {
    it('removes search from searchCount', () => {
      localState.searchCount = mockSearches.length + 2;
      mockSearches.forEach(() => {
        mutations[types.DECREMENT_PROJECT_SEARCH_COUNT](localState, 1);
      });

      expect(localState.searchCount).toBe(2);
    });
  });

  describe('INCREMENT_PROJECT_SEARCH_COUNT', () => {
    it('adds search to searchCount', () => {
      mockSearches.forEach(() => {
        mutations[types.INCREMENT_PROJECT_SEARCH_COUNT](localState, 1);
      });

      expect(localState.searchCount).toBe(mockSearches.length);
    });
  });

  describe('SET_PROJECT_ENDPOINT_LIST', () => {
    it('sets project list endpoint', () => {
      mutations[types.SET_PROJECT_ENDPOINT_LIST](localState, mockEndpoint);

      expect(localState.projectEndpoints.list).toBe(mockEndpoint);
    });
  });

  describe('SET_PROJECT_ENDPOINT_ADD', () => {
    it('sets project add endpoint', () => {
      mutations[types.SET_PROJECT_ENDPOINT_ADD](localState, mockEndpoint);

      expect(localState.projectEndpoints.add).toBe(mockEndpoint);
    });
  });

  describe('SET_PROJECTS', () => {
    it('sets projects', () => {
      mutations[types.SET_PROJECTS](localState, projects);

      expect(localState.projects).toEqual(projects);
      expect(localState.isLoadingProjects).toEqual(false);
    });
  });

  describe('TOGGLE_IS_LOADING_PROJECTS', () => {
    it('toggles the isLoadingProjects boolean', () => {
      mutations[types.TOGGLE_IS_LOADING_PROJECTS](localState);

      expect(localState.isLoadingProjects).toEqual(true);

      mutations[types.TOGGLE_IS_LOADING_PROJECTS](localState);

      expect(localState.isLoadingProjects).toEqual(false);
    });
  });

  describe('SET_MESSAGE_MINIMUM_QUERY', () => {
    it('sets the messages.minimumQuery boolean', () => {
      mutations[types.SET_MESSAGE_MINIMUM_QUERY](localState, true);

      expect(localState.messages.minimumQuery).toEqual(true);

      mutations[types.SET_MESSAGE_MINIMUM_QUERY](localState, false);

      expect(localState.messages.minimumQuery).toEqual(false);
    });
  });

  describe('ADD_SELECTED_PROJECT', () => {
    it('adds a project to the list of selected projects', () => {
      mutations[types.ADD_SELECTED_PROJECT](localState, projects[0]);

      expect(localState.selectedProjects).toEqual([projects[0]]);
    });
  });

  describe('REMOVE_SELECTED_PROJECT', () => {
    it('removes a project from the list of selected projects', () => {
      mutations[types.ADD_SELECTED_PROJECT](localState, projects[0]);
      mutations[types.ADD_SELECTED_PROJECT](localState, projects[1]);
      mutations[types.REMOVE_SELECTED_PROJECT](localState, projects[0]);

      expect(localState.selectedProjects).toEqual([projects[1]]);
    });

    it('removes a project from the list of selected projects, including duplicates', () => {
      mutations[types.ADD_SELECTED_PROJECT](localState, projects[0]);
      mutations[types.ADD_SELECTED_PROJECT](localState, projects[0]);
      mutations[types.ADD_SELECTED_PROJECT](localState, projects[1]);
      mutations[types.REMOVE_SELECTED_PROJECT](localState, projects[0]);

      expect(localState.selectedProjects).toEqual([projects[1]]);
    });
  });

  describe('CLEAR_SEARCH_RESULTS', () => {
    it('empties both the search results and the list of selected projects', () => {
      localState.selectedProjects = [{ id: 1 }];
      localState.projectSearchResults = [{ id: 1 }];

      mutations[types.CLEAR_SEARCH_RESULTS](localState);

      expect(localState.projectSearchResults).toEqual([]);

      expect(localState.selectedProjects).toEqual([]);
    });
  });

  describe('SEARCHED_WITH_NO_QUERY', () => {
    it(`resets all messages and sets state.projectSearchResults to an empty array`, () => {
      localState.projectSearchResults = [{ id: 1 }];
      localState.messages = {
        noResults: true,
        searchError: true,
        minimumQuery: true,
      };

      mutations[types.SEARCHED_WITH_NO_QUERY](localState);

      expect(localState.projectSearchResults).toEqual([]);

      expect(localState.messages.noResults).toBe(false);

      expect(localState.messages.searchError).toBe(false);

      expect(localState.messages.minimumQuery).toBe(false);
    });
  });

  describe('SEARCHED_WITH_TOO_SHORT_QUERY', () => {
    it(`sets the appropriate messages and sets state.projectSearchResults to an empty array`, () => {
      localState.projectSearchResults = [{ id: 1 }];
      localState.messages = {
        noResults: true,
        searchError: true,
        minimumQuery: false,
      };

      mutations[types.SEARCHED_WITH_TOO_SHORT_QUERY](localState);

      expect(localState.projectSearchResults).toEqual([]);

      expect(localState.messages.noResults).toBe(false);

      expect(localState.messages.searchError).toBe(false);

      expect(localState.messages.minimumQuery).toBe(true);
    });
  });

  describe('SEARCHED_WITH_API_ERROR', () => {
    it(`sets the appropriate messages and sets state.projectSearchResults to an empty array`, () => {
      localState.projectSearchResults = [{ id: 1 }];
      localState.messages = {
        noResults: true,
        searchError: false,
        minimumQuery: true,
      };

      mutations[types.SEARCHED_WITH_API_ERROR](localState);

      expect(localState.projectSearchResults).toEqual([]);

      expect(localState.messages.noResults).toBe(false);

      expect(localState.messages.searchError).toBe(true);

      expect(localState.messages.minimumQuery).toBe(false);
    });
  });

  describe('SEARCHED_SUCCESSFULLY_WITH_RESULTS', () => {
    it(`resets all messages and sets state.projectSearchResults to the results from the API`, () => {
      localState.projectSearchResults = [];
      localState.messages = {
        noResults: true,
        searchError: true,
        minimumQuery: true,
      };

      const searchResults = [{ id: 1 }];

      mutations[types.SEARCHED_SUCCESSFULLY_WITH_RESULTS](localState, searchResults);

      expect(localState.projectSearchResults).toEqual(searchResults);

      expect(localState.messages.noResults).toBe(false);

      expect(localState.messages.searchError).toBe(false);

      expect(localState.messages.minimumQuery).toBe(false);
    });
  });

  describe('SEARCHED_SUCCESSFULLY_NO_RESULTS', () => {
    it(`sets the appropriate messages and sets state.projectSearchResults to an empty array`, () => {
      localState.projectSearchResults = [{ id: 1 }];
      localState.messages = {
        noResults: false,
        searchError: true,
        minimumQuery: true,
      };

      mutations[types.SEARCHED_SUCCESSFULLY_NO_RESULTS](localState);

      expect(localState.projectSearchResults).toEqual([]);

      expect(localState.messages.noResults).toBe(true);

      expect(localState.messages.searchError).toBe(false);

      expect(localState.messages.minimumQuery).toBe(false);
    });
  });

  describe('REQUEST_PROJECTS', () => {
    it('sets loading projects to true', () => {
      mutations[types.REQUEST_PROJECTS](localState);

      expect(localState.isLoadingProjects).toEqual(true);
    });
  });
});
