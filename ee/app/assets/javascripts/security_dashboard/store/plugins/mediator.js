import * as filtersMutationTypes from '../modules/filters/mutation_types';

export default store => {
  store.subscribe(({ type }) => {
    switch (type) {
      case `filters/${filtersMutationTypes.SET_ALL_FILTERS}`:
      case `filters/${filtersMutationTypes.SET_FILTER}`:
      case `filters/${filtersMutationTypes.SET_TOGGLE_VALUE}`: {
        const activeFilters = store.getters['filters/activeFilters'];
        store.dispatch('vulnerabilities/fetchVulnerabilities', activeFilters);
        store.dispatch('vulnerabilities/fetchVulnerabilitiesCount', activeFilters);
        store.dispatch('vulnerabilities/fetchVulnerabilitiesHistory', activeFilters);
        break;
      }
      default:
    }
  });
};
