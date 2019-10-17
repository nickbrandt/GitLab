import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import Component from 'ee/analytics/code_analytics/components/app.vue';
import GroupsDropdownFilter from 'ee/analytics/shared/components/groups_dropdown_filter.vue';
import ProjectsDropdownFilter from 'ee/analytics/shared/components/projects_dropdown_filter.vue';
import FileQuantityDropdown from 'ee/analytics/code_analytics/components/file_quantity_dropdown.vue';
import { group, project, DEFAULT_FILE_QUANTITY } from '../mock_data';

const emptyStateTitle = 'Identify the most frequently changed files in your repository';
const emptyStateDescription =
  'Identify areas of the codebase associated with a lot of churn, which can indicate potential code hotspots.';
const emptyStateSvgPath = 'path/to/empty/state';

const localVue = createLocalVue();
localVue.use(Vuex);

let wrapper;

const createComponent = (opts = {}) =>
  shallowMount(Component, {
    localVue,
    sync: false,
    propsData: {
      emptyStateSvgPath,
    },
    ...opts,
  });

describe('Code Analytics component', () => {
  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('mounted', () => {
    const actionSpies = {
      setSelectedFileQuantity: jest.fn(),
    };

    beforeEach(() => {
      wrapper = createComponent({ methods: actionSpies });
    });

    it('dispatches setSelectedFileQuantity with DEFAULT_FILE_QUANTITY', () => {
      expect(actionSpies.setSelectedFileQuantity).toHaveBeenCalledWith(DEFAULT_FILE_QUANTITY);
    });
  });

  describe('methods', () => {
    describe('onProjectSelect', () => {
      it('sets the project to null if no projects are submitted', () => {
        wrapper.vm.onProjectSelect([]);

        expect(wrapper.vm.$store.state.selectedProject).toBe(null);
      });

      it('sets the project correctly when submitted', () => {
        wrapper.vm.onProjectSelect([project]);

        expect(wrapper.vm.$store.state.selectedProject).toBe(project);
      });
    });
  });

  describe('displays the components as required', () => {
    describe('before a group has been selected', () => {
      it('displays an empty state', () => {
        const emptyState = wrapper.find(GlEmptyState);

        expect(emptyState.exists()).toBeTruthy();
        expect(emptyState.props('title')).toBe(emptyStateTitle);
        expect(emptyState.props('description')).toBe(emptyStateDescription);
        expect(emptyState.props('svgPath')).toBe(emptyStateSvgPath);
      });

      it('shows the groups filter', () => {
        expect(wrapper.find(GroupsDropdownFilter).exists()).toBeTruthy();
      });

      it('does not show the projects filter', () => {
        expect(wrapper.find(ProjectsDropdownFilter).exists()).toBeFalsy();
      });

      it('does not show the file quantity filter', () => {
        expect(wrapper.find(FileQuantityDropdown).exists()).toBeFalsy();
      });
    });

    describe('after a group has been selected', () => {
      beforeEach(() => {
        wrapper.vm.$store.state.selectedGroup = group;
      });

      describe('with no project selected', () => {
        beforeEach(() => {
          wrapper.vm.$store.state.selectedProject = null;
        });

        it('still displays an empty state', () => {
          const emptyState = wrapper.find(GlEmptyState);

          expect(emptyState.exists()).toBeTruthy();
          expect(emptyState.props('title')).toBe(emptyStateTitle);
          expect(emptyState.props('description')).toBe(emptyStateDescription);
          expect(emptyState.props('svgPath')).toBe(emptyStateSvgPath);
        });

        it('still shows the groups filter', () => {
          expect(wrapper.find(GroupsDropdownFilter).exists()).toBeTruthy();
        });

        it('shows the projects filter', () => {
          expect(wrapper.find(ProjectsDropdownFilter).exists()).toBeTruthy();
        });

        it('does not show the file quantity filter', () => {
          expect(wrapper.find(FileQuantityDropdown).exists()).toBeFalsy();
        });
      });

      describe('with a project selected', () => {
        beforeEach(() => {
          wrapper.vm.$store.state.selectedProject = project;
        });

        // This is until the empty state is replaced in a future iteration
        // https://gitlab.com/gitlab-org/gitlab/merge_requests/18395
        it('still displays an empty state', () => {
          const emptyState = wrapper.find(GlEmptyState);

          expect(emptyState.exists()).toBeTruthy();
          expect(emptyState.props('title')).toBe(emptyStateTitle);
          expect(emptyState.props('description')).toBe(emptyStateDescription);
          expect(emptyState.props('svgPath')).toBe(emptyStateSvgPath);
        });

        it('still shows the groups filter', () => {
          expect(wrapper.find(GroupsDropdownFilter).exists()).toBeTruthy();
        });

        it('shows the projects filter', () => {
          expect(wrapper.find(ProjectsDropdownFilter).exists()).toBeTruthy();
        });

        it('shows the file quantity filter', () => {
          expect(wrapper.find(FileQuantityDropdown).exists()).toBeTruthy();
        });
      });
    });
  });
});
