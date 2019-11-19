import Vuex from 'vuex';
import createStore from 'ee/security_dashboard/store';
import { BASE_FILTERS } from 'ee/security_dashboard/store/modules/filters/constants';
import projectSelectorModule from 'ee/security_dashboard/store/modules/project_selector';
import projectSelectorPlugin from 'ee/security_dashboard/store/plugins/project_selector';
import * as projectSelectorMutationTypes from 'ee/security_dashboard/store/modules/projects/mutation_types';

describe('project selector plugin', () => {
  let store;

  beforeEach(() => {
    jest.spyOn(Vuex.Store.prototype, 'registerModule');
    store = createStore({ plugins: [projectSelectorPlugin] });
  });

  it('registers the project selector module on the store', () => {
    expect(Vuex.Store.prototype.registerModule).toHaveBeenCalledTimes(1);
    expect(Vuex.Store.prototype.registerModule).toHaveBeenCalledWith(
      'projectSelector',
      projectSelectorModule(),
    );
  });

  it('sets project filter options with lazy = true after projects have been received', () => {
    jest.spyOn(store, 'dispatch').mockImplementation();
    const projects = [{ name: 'foo', id: '1' }];

    store.commit(
      `projectSelector/${projectSelectorMutationTypes.RECEIVE_PROJECTS_SUCCESS}`,
      projects,
    );

    expect(store.dispatch).toHaveBeenCalledTimes(1);
    expect(store.dispatch).toHaveBeenCalledWith('filters/setFilterOptions', {
      filterId: 'project_id',
      options: [BASE_FILTERS.project_id, ...projects],
      lazy: true,
    });
  });
});
