import state from 'ee/operations/store/state';
import mutations from 'ee/operations/store/mutations';
import * as types from 'ee/operations/store/mutation_types';
import { mockProjectData } from '../mock_data';

describe('mutations', () => {
  const projects = mockProjectData(1);
  const [oneProject] = projects;
  const mockEndpoint = 'https://mock-endpoint';
  const mockSearches = new Array(5).fill(null);
  let localState;

  beforeEach(() => {
    localState = state();
  });

  describe('ADD_PROJECT_TOKEN', () => {
    it('adds project token to projectTokens', () => {
      mutations[types.ADD_PROJECT_TOKEN](localState, oneProject);

      expect(localState.projectTokens[0]).toEqual(oneProject);
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

  describe('DECREMENT_PROJECT_SEARCH_COUNT', () => {
    it('removes search from searchCount', () => {
      localState.searchCount = mockSearches.length + 2;
      mockSearches.forEach(() => {
        mutations[types.DECREMENT_PROJECT_SEARCH_COUNT](localState, 1);
      });

      expect(localState.searchCount).toBe(2);
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

  describe('SET_PROJECT_SEARCH_RESULTS', () => {
    it('sets project search results', () => {
      mutations[types.SET_PROJECT_SEARCH_RESULTS](localState, projects);

      expect(localState.projectSearchResults).toEqual(projects);
    });
  });

  describe('SET_PROJECTS', () => {
    it('sets projects', () => {
      mutations[types.SET_PROJECTS](localState, projects);

      expect(localState.projects).toEqual(projects);
    });
  });

  describe('REMOVE_PROJECT_TOKEN_AT', () => {
    it('removes project token', () => {
      localState.projectTokens = projects;
      mutations[types.REMOVE_PROJECT_TOKEN_AT](localState, oneProject.id);

      expect(localState.projectTokens.length).toBe(0);
    });
  });
});
