import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import ProjectList from 'ee/security_dashboard/components/instance/instance_settings_project_list.vue';
import ProjectManager from 'ee/security_dashboard/components/instance/instance_settings_project_manager.vue';
import getProjects from 'ee/security_dashboard/graphql/queries/get_projects.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import ProjectSelector from '~/vue_shared/components/project_selector/project_selector.vue';

jest.mock('~/flash');

const mockProject = { id: 1, name: 'Sample Project 1' };
const singleProjectList = [mockProject];
const multipleProjectsList = [
  { id: 2, name: 'Sample Project 2' },
  { id: 3, name: 'Sample Project 3' },
];
const mockPageInfo = { hasNextPage: false, endCursor: '' };

describe('Project Manager component', () => {
  let wrapper;
  let spyQuery;
  let spyMutate;

  const defaultMocks = {
    $apollo: {
      query: jest.fn().mockResolvedValue({
        data: { projects: { nodes: singleProjectList, pageInfo: mockPageInfo } },
      }),
      mutate: jest.fn().mockResolvedValue({}),
    },
  };

  const defaultProps = {
    isManipulatingProjects: false,
    projects: [],
  };

  const createWrapper = ({ data = {}, mocks = {}, props = {} }) => {
    spyQuery = defaultMocks.$apollo.query;
    spyMutate = defaultMocks.$apollo.mutate;
    wrapper = shallowMount(ProjectManager, {
      data() {
        return { ...data };
      },
      mocks: { ...defaultMocks, ...mocks },
      propsData: { ...defaultProps, ...props },
    });
  };

  const findAddProjectsButton = () => wrapper.find(GlButton);
  const findProjectList = () => wrapper.find(ProjectList);
  const findProjectSelector = () => wrapper.find(ProjectSelector);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('it renders', () => {
    beforeEach(() => createWrapper({}));

    it('contains a project-selector component', () => {
      expect(findProjectSelector().exists()).toBe(true);
    });

    it('contains a project-list component', () => {
      expect(findProjectList().exists()).toBe(true);
    });

    it('contains the add project button', () => {
      expect(findAddProjectsButton().exists()).toBe(true);
    });
  });

  describe('searching projects', () => {
    beforeEach(() => createWrapper({}));

    it('searches with the query', () => {
      findProjectSelector().vm.$emit('searched', 'test');
      expect(spyQuery).toHaveBeenCalledTimes(1);
      expect(spyQuery).toHaveBeenCalledWith({
        query: getProjects,
        variables: {
          search: 'test',
          first: wrapper.vm.$options.PROJECTS_PER_PAGE,
          after: '',
          searchNamespaces: true,
          sort: 'similarity',
        },
      });
    });

    it('does not search if the query is below the minimum query limit', () => {
      findProjectSelector().vm.$emit('searched', 'te');
      expect(spyQuery).not.toHaveBeenCalled();
    });

    it('passes the search results to the project-selector on a successful search', () => {
      findProjectSelector().vm.$emit('searched', 'test');
      return waitForPromises().then(() => {
        expect(findProjectSelector().props('projectSearchResults')).toBe(singleProjectList);
      });
    });

    it('passes an empty array to the project-selector on a failed search', () => {
      const mocks = {
        $apollo: {
          query: jest.fn().mockRejectedValue(),
        },
      };
      createWrapper({ data: { selectedProjects: singleProjectList }, mocks });
      findProjectSelector().vm.$emit('searched', 'test');
      return waitForPromises().then(() => {
        expect(findProjectSelector().props('projectSearchResults')).toEqual([]);
      });
    });
  });

  describe('project selection', () => {
    it('adds a project to the list of selected projects', () => {
      createWrapper({});
      findProjectSelector().vm.$emit('projectClicked', mockProject);
      return waitForPromises().then(() => {
        expect(findProjectSelector().props('selectedProjects')).toEqual(singleProjectList);
      });
    });

    it('removes a project from the list of selected projects', () => {
      createWrapper({ data: { selectedProjects: singleProjectList } });
      findProjectSelector().vm.$emit('projectClicked', mockProject);
      return waitForPromises().then(() => {
        expect(findProjectSelector().props('selectedProjects')).toEqual([]);
      });
    });
  });

  describe('adding projects', () => {
    it('disables the add project button if no projects are selected', () => {
      createWrapper({});
      expect(findAddProjectsButton().attributes('disabled')).toBe('true');
    });

    it('enables the add project button if projects are selected', () => {
      createWrapper({ data: { selectedProjects: singleProjectList } });
      expect(findAddProjectsButton().attributes('disabled')).toBeFalsy();
    });

    it('adding a project successfully updates the projects list', () => {
      createWrapper({ data: { selectedProjects: singleProjectList } });
      findAddProjectsButton().vm.$emit('click');
      expect(spyMutate).toHaveBeenCalledTimes(1);
    });

    it('adding a project unsuccessfully shows a flash', () => {
      const mocks = {
        $apollo: {
          mutate: jest.fn().mockRejectedValue(),
        },
      };
      createWrapper({ data: { selectedProjects: singleProjectList }, mocks });
      findAddProjectsButton().vm.$emit('click');
      return waitForPromises().then(() => {
        expect(createFlash).toHaveBeenCalledTimes(1);
        expect(createFlash).toHaveBeenCalledWith(
          'Unable to add Sample Project 1: Project was not found or you do not have permission to add this project to Security Dashboards.',
        );
      });
    });

    it('adding many projects unsuccessfully shows a flash', () => {
      const mocks = {
        $apollo: {
          mutate: jest.fn().mockRejectedValue(),
        },
      };
      createWrapper({ data: { selectedProjects: multipleProjectsList }, mocks });
      findAddProjectsButton().vm.$emit('click');
      return waitForPromises().then(() => {
        expect(createFlash).toHaveBeenCalledTimes(1);
        expect(createFlash).toHaveBeenCalledWith(
          'Unable to add Sample Project 2 and Sample Project 3: Project was not found or you do not have permission to add this project to Security Dashboards.',
        );
      });
    });
  });

  describe('removing projects', () => {
    it('removing a project calls the mutatation', () => {
      createWrapper({ props: { projects: singleProjectList } });
      findProjectList().vm.$emit('projectRemoved', mockProject);
      expect(spyMutate).toHaveBeenCalledTimes(1);
    });

    it('removing a project unsuccessfully shows a flash', () => {
      const mocks = {
        $apollo: {
          mutate: jest.fn().mockRejectedValue(),
        },
      };
      createWrapper({ props: { selectedProjects: multipleProjectsList }, mocks });
      findProjectList().vm.$emit('projectRemoved', mockProject);
      return waitForPromises().then(() => {
        expect(createFlash).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('infinite scrolling', () => {
    it('if the bottom is reached and there is another page, it appends the next page to the projects array', () => {
      createWrapper({ data: { searchQuery: 'test' } });
      findProjectSelector().vm.$emit('bottomReached');
      expect(spyQuery).toHaveBeenCalledTimes(1);
    });

    it('if the bottom is reached and there is not another page, it does nothing', () => {
      createWrapper({ data: { pageInfo: { hasNextPage: false, endCursor: '' } } });
      findProjectSelector().vm.$emit('bottomReached');
      expect(spyQuery).not.toHaveBeenCalled();
    });
  });
});
