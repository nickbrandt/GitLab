import createStore from 'ee/security_dashboard/store/index';
import * as filtersMutationTypes from 'ee/security_dashboard/store/modules/filters/mutation_types';

describe('mediator', () => {
  let store;

  beforeEach(() => {
    store = createStore();
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
    spyOn(store, 'dispatch');

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
});
