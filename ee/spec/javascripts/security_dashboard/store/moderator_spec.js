import createStore from 'ee/security_dashboard/store/index';
import * as projectsMutationTypes from 'ee/security_dashboard/store/modules/projects/mutation_types';
import * as filtersMutationTypes from 'ee/security_dashboard/store/modules/filters/mutation_types';

describe('moderator', () => {
  let store;

  beforeEach(() => {
    store = createStore();
  });

  it('sets project filter options after projects have been received', () => {
    spyOn(store, 'dispatch').and.returnValue();

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

  it('triggers fetching vulnerabilities after filters change', () => {
    spyOn(store, 'dispatch').and.returnValue();

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
});
