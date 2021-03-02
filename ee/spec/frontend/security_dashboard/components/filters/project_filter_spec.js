import { GlLoadingIcon } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import FilterBody from 'ee/security_dashboard/components/filters/filter_body.vue';
import FilterItem from 'ee/security_dashboard/components/filters/filter_item.vue';
import ProjectFilter from 'ee/security_dashboard/components/filters/project_filter.vue';
import groupProjectsSearch from 'ee/security_dashboard/graphql/queries/group_projects_search.query.graphql';
import { getProjectFilter } from 'ee/security_dashboard/helpers';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';

const localVue = createLocalVue();
localVue.use(VueApollo);
localVue.use(VueRouter);
const router = new VueRouter();

jest.mock('~/flash');

describe('Project Filter component', () => {
  let wrapper;

  const createWrapper = ({ query }) => {
    wrapper = extendedWrapper(
      shallowMount(ProjectFilter, {
        localVue,
        router,
        apolloProvider: createMockApollo([query]),
        provide: { groupFullPath: 'path' },
        propsData: { filter: getProjectFilter([]) },
      }),
    );
  };

  const getLookupMockResult = (projects = []) => {
    return jest.fn().mockResolvedValue({
      data: {
        projects: {
          nodes: projects,
        },
      },
    });
  };

  const getSearchMockResult = (projects = []) => {
    return jest.fn().mockResolvedValue({
      data: {
        group: {
          projects: {
            nodes: projects,
          },
        },
      },
    });
  };

  const createLookupQuery = (handler) => [projectsFromIds, handler];
  const createSearchQuery = (handler) => [groupProjectsSearch, handler];

  afterEach(async () => {
    try {
      await router.push('/');
    } catch {
      // Setting the same route as the current one will throw an error. We'll just ignore it.
    }

    wrapper.destroy();
  });

  describe('selected projects lookup query', () => {
    it('does not run the query when the querystring does not have projects', () => {
      const queryHandler = getLookupMockResult();
      createWrapper({ query: createLookupQuery(queryHandler) });

      expect(queryHandler).not.toHaveBeenCalled();
    });

    describe('when the querystring has projects', () => {
      beforeEach(() => {
        router.replace({ query: { projectId: [1, 2, 3] } });
      });

      it('shows the filter body as loading and runs the query', () => {
        const queryHandler = getLookupMockResult();
        createWrapper({ query: createLookupQuery(queryHandler) });

        expect(wrapper.find(FilterBody).props('loading')).toBe(true);
        expect(queryHandler).toHaveBeenCalledTimes(1);
      });

      it('shows the filter body as not loading after the query finishes', async () => {
        const queryHandler = getLookupMockResult();
        createWrapper({ query: createLookupQuery(queryHandler) });
        await nextTick();

        expect(wrapper.find(FilterBody).props('loading')).toBe(false);
        expect(queryHandler).toHaveBeenCalledTimes(1);
      });

      it('shows an error message if the query fails', async () => {
        const queryHandler = jest.fn().mockRejectedValue([]);
        createWrapper({ query: createLookupQuery(queryHandler) });
        await waitForPromises();

        expect(queryHandler).toHaveBeenCalledTimes(1);
        expect(wrapper.find(FilterBody).props('loading')).toBe(false);
        expect(createFlash).toHaveBeenCalled();
      });
    });
  });

  describe('projects search query', () => {
    it('does not run the query if the dropdown has never been opened', () => {
      const queryHandler = getSearchMockResult();
      createWrapper({ query: createSearchQuery(queryHandler) });

      expect(queryHandler).not.toHaveBeenCalled();
    });

    it('runs the query and shows the loading spinner when the dropdown is opened for the first time', async () => {
      const queryHandler = getSearchMockResult();
      createWrapper({ query: createSearchQuery(queryHandler) });
      wrapper.find(FilterBody).vm.$emit('dropdown-show');
      await nextTick();

      expect(queryHandler).toHaveBeenCalledTimes(1);
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.findAllComponents(FilterItem)).toHaveLength(0);
    });

    it('shows an error message if the query fails', async () => {
      const queryHandler = jest.fn().mockRejectedValue([]);
      createWrapper({ query: createSearchQuery(queryHandler) });
      wrapper.find(FilterBody).vm.$emit('dropdown-show');
      await waitForPromises();

      expect(queryHandler).toHaveBeenCalledTimes(1);
      expect(createFlash).toHaveBeenCalled();
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
    });

    it('shows the projects after the query is done', async () => {
      const queryHandler = getSearchMockResult([
        { id: 1, name: 'Project 1' },
        { id: 2, name: 'Project 2' },
        { id: 3, name: 'Project 3' },
      ]);
      createWrapper({ query: createSearchQuery(queryHandler) });
      wrapper.find(FilterBody).vm.$emit('dropdown-show');
      await waitForPromises();
      await nextTick();
      await nextTick();
      await nextTick();
      await nextTick();

      expect(wrapper.findAllComponents(FilterItem)).toHaveLength(5);
    });
  });

  describe('dropdown initial open/close', () => {
    it('does not run the projects query when the dropdown has not been opened', () => {});

    it('runs the projects query and shows a spinner when the dropdown is opened for the first time', () => {});

    it('shows the projects after the query is done', () => {});

    it('does not run the projects query a second time after the dropdown has been opened once and opened again', () => {});
  });

  describe('selecting and de-selecting projects when there is no search filter', () => {
    it('moves an unselected project into the selected projects section when clicked', () => {});

    it('moves a selected project into the unselected projects section when clicked', () => {});
  });

  describe('selecting and de-selecting projects when there is a search filter', () => {
    it('does not show the selected items section', () => {});

    it('select a projects in-place when it is clicked', () => {});
  });

  describe('search box', () => {
    it('shows a message to enter 3+ characters and does not perform a search', () => {});

    it('performs a search when there are 3+ characters', () => {});

    it('highlights the search term in the results', () => {});
  });

  describe('selected projects limit', () => {
    it('shows the project list and hides the limit message when there are less than 100 projects selected', () => {});

    it('hides the project list and shows the limit message when there are 100 projects selected', () => {});
  });

  describe('querystring behavior', () => {
    it('pre-selects the projects from the querystring and immediately fires an event', () => {});

    it('should not run selected projects query when querystring changes due to clicking on dropdown items', () => {});

    it('should run selected projects query when querystring changes due to browser navigation', () => {});
  });
});
