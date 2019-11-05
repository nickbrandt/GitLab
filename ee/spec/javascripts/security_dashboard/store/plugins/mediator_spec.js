import createStore from 'ee/security_dashboard/store/index';
import * as filtersMutationTypes from 'ee/security_dashboard/store/modules/filters/mutation_types';

describe('mediator', () => {
  let store;

  beforeEach(() => {
    store = createStore();
    spyOn(store, 'dispatch');
  });

  it('triggers fetching vulnerabilities after one filter changes', () => {
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

  it('does not fetch vulnerabilities after one filter changes with lazy = true', () => {
    store.commit(`filters/${filtersMutationTypes.SET_FILTER}`, { lazy: true });

    expect(store.dispatch).not.toHaveBeenCalled();
  });

  it('triggers fetching vulnerabilities after filters change', () => {
    const payload = {
      ...store.getters['filters/activeFilters'],
      page: store.state.vulnerabilities.pageInfo.page,
    };

    store.commit(`filters/${filtersMutationTypes.SET_ALL_FILTERS}`, {});

    expect(store.dispatch).toHaveBeenCalledTimes(3);
    expect(store.dispatch).toHaveBeenCalledWith('vulnerabilities/fetchVulnerabilities', payload);

    expect(store.dispatch).toHaveBeenCalledWith(
      'vulnerabilities/fetchVulnerabilitiesCount',
      payload,
    );

    expect(store.dispatch).toHaveBeenCalledWith(
      'vulnerabilities/fetchVulnerabilitiesHistory',
      payload,
    );
  });

  it('triggers fetching vulnerabilities after "Hide dismissed" toggle changes', () => {
    const activeFilters = store.getters['filters/activeFilters'];

    store.commit(`filters/${filtersMutationTypes.SET_TOGGLE_VALUE}`, {});

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

  it('does not fetch vulnerabilities after "Hide dismissed" toggle changes with lazy = true', () => {
    store.commit(`filters/${filtersMutationTypes.SET_TOGGLE_VALUE}`, { lazy: true });

    expect(store.dispatch).not.toHaveBeenCalled();
  });
});
