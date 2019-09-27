import Vuex from 'vuex';
import createStore from 'ee/security_dashboard/store';
import projectsModule from 'ee/security_dashboard/store/modules/projects';
import projectsPlugin from 'ee/security_dashboard/store/plugins/projects';
import * as projectsMutationTypes from 'ee/security_dashboard/store/modules/projects/mutation_types';
import { BASE_FILTERS } from 'ee/security_dashboard/store/modules/filters/constants';

describe('projects plugin', () => {
  let store;

  beforeEach(() => {
    jest.spyOn(Vuex.Store.prototype, 'registerModule');
    store = createStore({ plugins: [projectsPlugin] });
  });

  it('registers the projects module on the store', () => {
    expect(Vuex.Store.prototype.registerModule).toHaveBeenCalledTimes(1);
    expect(Vuex.Store.prototype.registerModule).toHaveBeenCalledWith('projects', projectsModule);
  });

  it('sets project filter options after projects have been received', () => {
    jest.spyOn(store, 'dispatch').mockImplementation();
    const projectOption = { name: 'foo', id: '1' };

    store.commit(`projects/${projectsMutationTypes.RECEIVE_PROJECTS_SUCCESS}`, {
      projects: [{ ...projectOption, irrelevantProperty: 'foobar' }],
    });

    expect(store.dispatch).toHaveBeenCalledTimes(1);
    expect(store.dispatch).toHaveBeenCalledWith(
      'filters/setFilterOptions',
      Object({
        filterId: 'project_id',
        options: [BASE_FILTERS.project_id, projectOption],
      }),
    );
  });
});
