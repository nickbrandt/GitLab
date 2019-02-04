import * as vulnerabilitiesMutationTypes from './modules/vulnerabilities/mutation_types';
import * as filtersMutationTypes from './modules/filters/mutation_types';
import * as projectsMutationTypes from './modules/projects/mutation_types';

export default function configureModerator(store) {
  store.$router.beforeEach((to, from, next) => {
    const updatedFromState = (to.params && to.params.updatedFromState) || false;

    if (to.name === 'dashboard' && !updatedFromState) {
      store.dispatch(`filters/setAllFilters`, to.query);
    }

    next();
  });

  store.subscribe(({ type, payload }) => {
    switch (type) {
      case `projects/${projectsMutationTypes.RECEIVE_PROJECTS_SUCCESS}`:
        store.dispatch('filters/setFilterOptions', {
          filterId: 'project_id',
          options: [
            {
              name: 'All',
              id: 'all',
            },
            ...payload.projects.map(project => ({
              name: project.name,
              id: project.id.toString(),
            })),
          ],
        });
        break;
      case `filters/${filtersMutationTypes.SET_ALL_FILTERS}`:
      case `filters/${filtersMutationTypes.SET_FILTER}`: {
        const activeFilters = store.getters['filters/activeFilters'];
        store.dispatch('vulnerabilities/fetchVulnerabilities', activeFilters);
        store.dispatch('vulnerabilities/fetchVulnerabilitiesCount', activeFilters);
        store.dispatch('vulnerabilities/fetchVulnerabilitiesHistory', activeFilters);
        break;
      }
      case `vulnerabilities/${vulnerabilitiesMutationTypes.RECEIVE_VULNERABILITIES_SUCCESS}`: {
        const activeFilters = store.getters['filters/activeFilters'];
        store.$router.push({
          name: 'dashboard',
          query: activeFilters,
          params: { updatedFromState: true },
        });
        break;
      }
      default:
    }
  });
}
