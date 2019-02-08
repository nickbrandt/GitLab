import createStore from 'ee/security_dashboard/store/index';
import * as projectsMutationTypes from 'ee/security_dashboard/store/modules/projects/mutation_types';
import * as filtersMutationTypes from 'ee/security_dashboard/store/modules/filters/mutation_types';
import * as vulnerabilitiesMutationTypes from 'ee/security_dashboard/store/modules/vulnerabilities/mutation_types';

describe('moderator', () => {
  let store;

  beforeEach(() => {
    store = createStore();
  });

  it('sets project filter options after projects have been received', () => {
    spyOn(store, 'dispatch');

    store.commit(`projects/${projectsMutationTypes.RECEIVE_PROJECTS_SUCCESS}`, {
      projects: [{ name: 'foo', id: 1, otherProp: 'foobar' }],
    });

    expect(store.dispatch).toHaveBeenCalledTimes(1);
    expect(store.dispatch).toHaveBeenCalledWith(
      'filters/setFilterOptions',
      Object({
        filterId: 'project_id',
        options: [{ name: 'All', id: 'all' }, { name: 'foo', id: '1' }],
      }),
    );
  });

  it('triggers fetching vulnerabilities after one filter changes', () => {
    spyOn(store, 'dispatch');

    const activeFilters = store.getters['filters/activeFilters'];

    store.commit(`filters/${filtersMutationTypes.SET_FILTER}`, {});

    expect(store.dispatch).toHaveBeenCalledTimes(3);
    expect(store.dispatch).toHaveBeenCalledWith(
      'vulnerabilities/fetchVulnerabilities',
      activeFilters,
    );

    expect(store.dispatch).toHaveBeenCalledWith(
      'vulnerabilities/fetchVulnerabilitiesCount',
      activeFilters,
    );

    expect(store.dispatch).toHaveBeenCalledWith(
      'vulnerabilities/fetchVulnerabilitiesHistory',
      activeFilters,
    );
  });

  it('triggers fetching vulnerabilities after filters change', () => {
    spyOn(store, 'dispatch');

    const activeFilters = store.getters['filters/activeFilters'];

    store.commit(`filters/${filtersMutationTypes.SET_ALL_FILTERS}`, {});

    expect(store.dispatch).toHaveBeenCalledTimes(3);
    expect(store.dispatch).toHaveBeenCalledWith(
      'vulnerabilities/fetchVulnerabilities',
      activeFilters,
    );

    expect(store.dispatch).toHaveBeenCalledWith(
      'vulnerabilities/fetchVulnerabilitiesCount',
      activeFilters,
    );

    expect(store.dispatch).toHaveBeenCalledWith(
      'vulnerabilities/fetchVulnerabilitiesHistory',
      activeFilters,
    );
  });

  describe('routing', () => {
    it('updates store after URL changes', () => {
      const query = { example: ['test'] };

      spyOn(store, 'dispatch');

      store.$router.push({ name: 'dashboard', query });

      expect(store.dispatch).toHaveBeenCalledTimes(1);
      expect(store.dispatch).toHaveBeenCalledWith(`filters/setAllFilters`, query);
    });

    it("doesn't update the store if the URL update originated from the moderator", () => {
      const query = { example: ['test'] };

      spyOn(store, 'commit');

      store.$router.push({ name: 'dashboard', query, params: { updatedFromState: true } });

      expect(store.commit).toHaveBeenCalledTimes(0);
    });

    it('it updates the route after a successful vulnerability retrieval', () => {
      const activeFilters = store.getters['filters/activeFilters'];

      spyOn(store.$router, 'push');

      store.commit(
        `vulnerabilities/${vulnerabilitiesMutationTypes.RECEIVE_VULNERABILITIES_SUCCESS}`,
        {},
      );

      expect(store.$router.push).toHaveBeenCalledTimes(1);
      expect(store.$router.push).toHaveBeenCalledWith({
        name: 'dashboard',
        query: activeFilters,
        params: { updatedFromState: true },
      });
    });
  });
});
