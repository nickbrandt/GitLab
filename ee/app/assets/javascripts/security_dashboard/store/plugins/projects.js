import projectsModule from '../modules/projects';
import * as projectsMutationTypes from '../modules/projects/mutation_types';
import { BASE_FILTERS } from '../modules/filters/constants';

export default store => {
  store.registerModule('projects', projectsModule);

  store.subscribe(({ type, payload }) => {
    if (type === `projects/${projectsMutationTypes.RECEIVE_PROJECTS_SUCCESS}`) {
      store.dispatch('filters/setFilterOptions', {
        filterId: 'project_id',
        options: [
          BASE_FILTERS.project_id,
          ...payload.projects.map(({ name, id }) => ({
            name,
            id: id.toString(),
          })),
        ],
      });
    }
  });
};
