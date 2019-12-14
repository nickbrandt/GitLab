import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';

import createDefaultState from 'ee/security_dashboard/store/modules/project_selector/state';

import { GlButton } from '@gitlab/ui';

import ProjectManager from 'ee/security_dashboard/components/project_manager.vue';
import ProjectList from 'ee/security_dashboard/components/project_list.vue';
import ProjectSelector from '~/vue_shared/components/project_selector/project_selector.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Project Manager component', () => {
  let storeOptions;
  let store;
  let wrapper;

  const factory = ({
    state = {},
    canAddProjects = false,
    isSearchingProjects = false,
    isUpdatingProjects = false,
  } = {}) => {
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
          getters: {
            canAddProjects: jest.fn().mockReturnValue(canAddProjects),
            isSearchingProjects: jest.fn().mockReturnValue(isSearchingProjects),
            isUpdatingProjects: jest.fn().mockReturnValue(isUpdatingProjects),
          },
          state: {
            ...createDefaultState(),
            ...state,
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

    it('dispatches the addProjects when the "Add projects" button has been clicked', () => {
      getAddProjectsButton().vm.$emit('click');

      expect(getMockAction('addProjects')).toHaveBeenCalled();
    });

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

  describe('given the store state', () => {
    it.each`
      config                                             | projectSelectorPropName            | expectedPropValue
      ${{ isSearchingProjects: true }}                   | ${'showLoadingIndicator'}          | ${true}
      ${{ state: { selectedProjects: ['bar'] } }}        | ${'selectedProjects'}              | ${['bar']}
      ${{ state: { projectSearchResults: ['foo'] } }}    | ${'projectSearchResults'}          | ${['foo']}
      ${{ state: { messages: { noResults: true } } }}    | ${'showNoResultsMessage'}          | ${true}
      ${{ state: { messages: { searchError: true } } }}  | ${'showSearchErrorMessage'}        | ${true}
      ${{ state: { messages: { minimumQuery: true } } }} | ${'showMinimumSearchQueryMessage'} | ${true}
    `(
      'passes $projectSelectorPropName = $expectedPropValue to the project-selector',
      ({ config, projectSelectorPropName, expectedPropValue }) => {
        factory(config);

        expect(getProjectSelector().props(projectSelectorPropName)).toEqual(expectedPropValue);
      },
    );

    it('enables the add-projects button when projects can be added', () => {
      factory({ canAddProjects: true });

      expect(getAddProjectsButton().attributes('disabled')).toBe(undefined);
    });

    it('passes the list of projects to the project-list component', () => {
      const projects = [{}];

      factory({ state: { projects } });

      expect(getProjectList().props('projects')).toBe(projects);
    });

    it.each([false, true])(
      'passes showLoadingIndicator = %p to the project-list component',
      isUpdatingProjects => {
        factory({ isUpdatingProjects });

        expect(getProjectList().props('showLoadingIndicator')).toBe(isUpdatingProjects);
      },
    );
  });
});
