import * as projectsMutationTypes from './modules/projects/mutation_types';

export default function configureModerator(store) {
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
      default:
    }
  });
}
