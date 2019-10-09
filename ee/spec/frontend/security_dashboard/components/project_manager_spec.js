import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';

import createDefaultState from 'ee/security_dashboard/store/modules/project_selector/state';

import { GlButton, GlLoadingIcon } from '@gitlab/ui';

import ProjectSelector from '~/vue_shared/components/project_selector/project_selector.vue';
import ProjectManager from 'ee/security_dashboard/components/project_manager.vue';
import ProjectList from 'ee/security_dashboard/components/project_list.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Project Manager component', () => {
  let storeOptions;
  let store;
  let wrapper;

  const factory = ({ stateOverrides = {} } = {}) => {
    storeOptions = {
      modules: {
        projectSelector: {
          namespaced: true,
          actions: {
            setSearchQuery: jest.fn(),
            fetchSearchResults: jest.fn(),
            addProjects: jest.fn(),
            clearSearchResults: jest.fn(),
            toggleSelectedProject: jest.fn(),
            removeProject: jest.fn(),
          },
          state: {
            ...createDefaultState(),
            ...stateOverrides,
          },
        },
      },
    };

    store = new Vuex.Store(storeOptions);

    wrapper = shallowMount(ProjectManager, {
      localVue,
      store,
      sync: false,
    });
  };

  const getMockAction = actionName => storeOptions.modules.projectSelector.actions[actionName];
  const getMockActionDispatchedPayload = actionName => getMockAction(actionName).mock.calls[0][1];

  const getAddProjectsButton = () => wrapper.find(GlButton);
  const getLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const getProjectList = () => wrapper.find(ProjectList);
  const getProjectSelector = () => wrapper.find(ProjectSelector);

  afterEach(() => {
    wrapper.destroy();
    jest.clearAllMocks();
  });

  describe('given the default state', () => {
    beforeEach(factory);

    it('contains a project-selector component', () => {
      expect(getProjectSelector().exists()).toBe(true);
    });

    it.each`
      actionName              | payload
      ${'setSearchQuery'}     | ${'foo'}
      ${'fetchSearchResults'} | ${undefined}
    `(
      'dispatches the correct actions when a project-search has been triggered',
      ({ actionName, payload }) => {
        getProjectSelector().vm.$emit('searched', payload);
        expect(getMockActionDispatchedPayload(actionName)).toBe(payload);
      },
    );

    it('contains a button for adding selected projects', () => {
      expect(getAddProjectsButton().text()).toContain('Add projects');
    });

    it('disables the button for adding projects per default', () => {
      expect(getAddProjectsButton().attributes('disabled')).toBe('true');
    });

    it.each`
      actionName              | payload
      ${'addProjects'}        | ${undefined}
      ${'clearSearchResults'} | ${undefined}
    `(
      'dispatches the correct actions when the add-projects button has been clicked',
      ({ actionName, payload }) => {
        getAddProjectsButton().vm.$emit('click');

        expect(getMockActionDispatchedPayload(actionName)).toBe(payload);
      },
    );

    it('contains a project-list component', () => {
      expect(getProjectList().exists()).toBe(true);
    });

    it('dispatches the right actions when the project-list emits a projectRemoved event', () => {
      const mockProject = { remove_path: 'foo' };
      const projectList = wrapper.find(ProjectList);
      const removeProjectAction = getMockAction('removeProject');

      projectList.vm.$emit('projectRemoved', mockProject);

      expect(removeProjectAction).toHaveBeenCalledTimes(1);
      expect(removeProjectAction.mock.calls[0][1]).toBe(mockProject.remove_path);
    });
  });

  describe('given the state changes', () => {
    it.each`
      state                                   | projectSelectorPropName            | expectedPropValue
      ${{ searchCount: 1 }}                   | ${'showLoadingIndicator'}          | ${true}
      ${{ selectedProjects: ['bar'] }}        | ${'selectedProjects'}              | ${['bar']}
      ${{ projectSearchResults: ['foo'] }}    | ${'projectSearchResults'}          | ${['foo']}
      ${{ messages: { noResults: true } }}    | ${'showNoResultsMessage'}          | ${true}
      ${{ messages: { searchError: true } }}  | ${'showSearchErrorMessage'}        | ${true}
      ${{ messages: { minimumQuery: true } }} | ${'showMinimumSearchQueryMessage'} | ${true}
    `(
      'passes the correct prop-values to the project-selector',
      ({ state, projectSelectorPropName, expectedPropValue }) => {
        factory({ stateOverrides: state });

        expect(getProjectSelector().props(projectSelectorPropName)).toEqual(expectedPropValue);
      },
    );

    it('enables the add-projects button when at least one projects is selected', () => {
      factory({ stateOverrides: { selectedProjects: [{}] } });

      expect(getAddProjectsButton().attributes('disabled')).toBe(undefined);
    });

    it('passes the list of projects to the project-list component', () => {
      const projects = [{}];

      factory({ stateOverrides: { projects } });

      expect(getProjectList().props('projects')).toBe(projects);
    });

    it('toggles the loading icon when a project is being added', () => {
      factory({ stateOverrides: { isAddingProjects: false } });

      expect(getLoadingIcon().exists()).toBe(false);

      store.state.projectSelector.isAddingProjects = true;

      return wrapper.vm.$nextTick().then(() => {
        expect(getLoadingIcon().exists()).toBe(true);
      });
    });
  });
});
