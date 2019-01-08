import * as projectsMutationTypes from './modules/projects/mutation_types';

export default function configureModerator(store) {
  store.subscribe(({ type, payload }) => {
    switch (type) {
      case `projects/${projectsMutationTypes.RECEIVE_PROJECTS_SUCCESS}`:
        return store.dispatch('filters/setFilterOptions', {
          filterId: 'project',
          options: [
            {
              name: 'All',
              id: 'all',
              selected: true,
            },
            ...payload.projects.map(project => ({
              name: project.name,
              id: project.id.toString(),
              selected: false,
            })),
          ],
        });
      default:
        return null;
    }
  });
}
