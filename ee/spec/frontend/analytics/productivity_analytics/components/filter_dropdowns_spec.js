import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import FilterDropdowns from 'ee/analytics/productivity_analytics/components/filter_dropdowns.vue';
import GroupsDropdownFilter from 'ee/analytics/shared/components/groups_dropdown_filter.vue';
import ProjectsDropdownFilter from 'ee/analytics/shared/components/projects_dropdown_filter.vue';
import store from 'ee/analytics/productivity_analytics/store';
import resetStore from '../helpers';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('FilterDropdowns component', () => {
  let wrapper;

  const actionSpies = {
    setGroupNamespace: jest.fn(),
    setProjectPath: jest.fn(),
  };

  const groupId = 1;
  const groupNamespace = 'gitlab-org';
  const projectPath = 'gitlab-org/gitlab-test';
  const projectId = 10;

  beforeEach(() => {
    wrapper = shallowMount(FilterDropdowns, {
      localVue,
      store,
      propsData: {},
      methods: {
        ...actionSpies,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    resetStore(store);
  });

  describe('template', () => {
    it('renders the groups dropdown', () => {
      expect(wrapper.find(GroupsDropdownFilter).exists()).toBe(true);
    });

    describe('without a group selected', () => {
      beforeEach(() => {
        wrapper.vm.groupId = null;
      });

      it('does not render the projects dropdown', () => {
        expect(wrapper.find(ProjectsDropdownFilter).exists()).toBe(false);
      });
    });

    describe('with a group selected', () => {
      beforeEach(() => {
        wrapper.vm.groupId = groupId;
      });

      it('renders the projects dropdown', () => {
        expect(wrapper.find(ProjectsDropdownFilter).exists()).toBe(true);
      });
    });
  });

  describe('methods', () => {
    describe('onGroupSelected', () => {
      beforeEach(() => {
        wrapper.vm.onGroupSelected({ id: groupId, full_path: groupNamespace });
      });

      it('updates the groupId and invokes setGroupNamespace action', () => {
        expect(wrapper.vm.groupId).toBe(1);
        expect(actionSpies.setGroupNamespace).toHaveBeenCalledWith(groupNamespace);
      });

      it('emits the "groupSelected" event', () => {
        expect(wrapper.emitted().groupSelected[0][0]).toEqual({
          groupNamespace,
          groupId,
        });
      });
    });

    describe('onProjectsSelected', () => {
      beforeEach(() => {
        wrapper.vm.groupId = groupId;
      });

      describe('when the list of selected projects is not empty', () => {
        beforeEach(() => {
          store.state.filters.groupNamespace = groupNamespace;
          wrapper.vm.onProjectsSelected([{ id: projectId, path_with_namespace: `${projectPath}` }]);
        });

        it('invokes setProjectPath action', () => {
          expect(actionSpies.setProjectPath).toHaveBeenCalledWith(projectPath);
        });

        it('emits the "projectSelected" event', () => {
          expect(wrapper.emitted().projectSelected[0][0]).toEqual({
            groupNamespace,
            groupId,
            projectNamespace: projectPath,
            projectId,
          });
        });
      });

      describe('when the list of selected projects is empty', () => {
        beforeEach(() => {
          store.state.filters.groupNamespace = groupNamespace;
          wrapper.vm.onProjectsSelected([]);
        });

        it('invokes setProjectPath action with null', () => {
          expect(actionSpies.setProjectPath).toHaveBeenCalledWith(null);
        });

        it('emits the "projectSelected" event', () => {
          expect(wrapper.emitted().projectSelected[0][0]).toEqual({
            groupNamespace,
            groupId,
            projectNamespace: null,
            projectId: null,
          });
        });
      });
    });
  });
});
