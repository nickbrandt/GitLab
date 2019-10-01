import * as filtersMutationTypes from '../modules/filters/mutation_types';

export default store => {
  const refreshVulnerabilities = payload => {
    store.dispatch('vulnerabilities/fetchVulnerabilities', payload);
    store.dispatch('vulnerabilities/fetchVulnerabilitiesCount', payload);
    store.dispatch('vulnerabilities/fetchVulnerabilitiesHistory', payload);
  };

  store.subscribe(({ type }) => {
    switch (type) {
      // SET_ALL_FILTERS mutations are triggered by navigation events, in such case we
      // want to preserve the page number that was set in the sync_with_router plugin
      case `filters/${filtersMutationTypes.SET_ALL_FILTERS}`:
        refreshVulnerabilities({
          ...store.getters['filters/activeFilters'],
          page: store.state.vulnerabilities.pageInfo.page,
        });
        break;
      // SET_FILTER and SET_TOGGLE_VALUE mutations happen when users interact with the UI,
      // in that case we want to reset the page number
      case `filters/${filtersMutationTypes.SET_FILTER}`:
      case `filters/${filtersMutationTypes.SET_TOGGLE_VALUE}`: {
        refreshVulnerabilities(store.getters['filters/activeFilters']);
        break;
      }
      default:
    }
  });
};
