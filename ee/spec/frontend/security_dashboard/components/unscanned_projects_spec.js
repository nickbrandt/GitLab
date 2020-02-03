import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';

import { GlTab } from '@gitlab/ui';

import UnscannedProjects from 'ee/security_dashboard/components/unscanned_projects.vue';
import TabContent from 'ee/security_dashboard/components/unscanned_projects_tab_content.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('UnscannedProjects component', () => {
  let wrapper;
  let actions;
  let getters;
  let store;

  const defaultPropsData = { endpoint: 'foo/bar' };
  const defaultOutdatedCount = 99;
  const defaultUntestedCount = 98;

  const factory = ({
    propsData = {},
    outdatedProjects = [],
    untestedProjects = [],
    outdatedProjectsCount = defaultOutdatedCount,
    untestedProjectsCount = defaultUntestedCount,
    isLoading = false,
  } = {}) => {
    const state = {
      isLoading,
      projects: [],
    };

    actions = {
      fetchUnscannedProjects: jest.fn(),
    };

    getters = {
      outdatedProjects: jest.fn(() => outdatedProjects),
      untestedProjects: jest.fn(() => untestedProjects),
      outdatedProjectsCount: jest.fn(() => outdatedProjectsCount),
      untestedProjectsCount: jest.fn(() => untestedProjectsCount),
    };

    store = new Vuex.Store({
      modules: {
        unscannedProjects: {
          namespaced: true,
          actions,
          getters,
          state,
        },
      },
    });

    wrapper = mount(UnscannedProjects, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
      store,
      localVue,
      sync: false,
    });
  };

  const outdatedProjectsTab = () => wrapper.find({ ref: 'outdatedProjectsTab' });
  const untestedProjectsTab = () => wrapper.find({ ref: 'untestedProjectsTab' });
  const outdatedProjectsTabContent = () => outdatedProjectsTab().find(TabContent);
  const untestedProjectsTabContent = () => untestedProjectsTab().find(TabContent);
  const outdatedProjectsCount = () => wrapper.find({ ref: 'outdatedProjectsCount' });
  const untestedProjectsCount = () => wrapper.find({ ref: 'untestedProjectsCount' });

  beforeEach(factory);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('lifecycle hooks', () => {
    it('fetches projects from the given endpoint when the component is created', () => {
      factory();
      expect(actions.fetchUnscannedProjects).toHaveBeenCalledTimes(1);
      expect(actions.fetchUnscannedProjects.mock.calls[0][1]).toBe(defaultPropsData.endpoint);
    });
  });

  describe('header', () => {
    it('matches the snapshot', () => {
      expect(wrapper.find('header').element).toMatchSnapshot();
    });
  });

  describe('tab buttons', () => {
    it('shows a tab-button for projects which have outdated security scanning', () => {
      expect(outdatedProjectsTab().is(GlTab)).toBe(true);
    });

    it('shows a count of outdated projects', () => {
      expect(outdatedProjectsCount().text()).toContain(defaultOutdatedCount);
    });

    it('shows a tab-button for projects which have no security scanning configured', () => {
      expect(untestedProjectsTab().is(GlTab)).toBe(true);
    });

    it('shows a count of untested projects', () => {
      expect(untestedProjectsCount().text()).toContain(defaultUntestedCount);
    });
  });

  describe('tab content', () => {
    it.each`
      type          | tabContent
      ${'outdated'} | ${outdatedProjectsTabContent}
      ${'untested'} | ${untestedProjectsTabContent}
    `(
      'passes the "isLoading" prop to the $type projects tab-content component',
      ({ tabContent }) => {
        expect(tabContent().props('isLoading')).toBe(false);

        factory({ isLoading: true });

        return wrapper.vm.$nextTick(() => {
          expect(tabContent().props('isLoading')).toBe(true);
        });
      },
    );

    it.each`
      type          | tabContent
      ${'outdated'} | ${outdatedProjectsTabContent}
      ${'untested'} | ${untestedProjectsTabContent}
    `(
      'passes the "isEmpty" prop to the $type projects tab-content component',
      ({ type, tabContent }) => {
        expect(tabContent().props('isEmpty')).toBe(false);

        factory({ [`${type}ProjectsCount`]: 0 });

        return wrapper.vm.$nextTick(() => {
          expect(tabContent().props('isEmpty')).toBe(true);
        });
      },
    );

    it('shows a list of outdated projects', () => {
      const outdatedProjects = [
        {
          description: 'Foo',
          projects: [{ fullPath: '/foo', fullName: 'Foo' }],
        },
      ];

      factory({ outdatedProjects });

      expect(outdatedProjectsTabContent().element).toMatchSnapshot();
    });

    it('shows a list of untested projects', () => {
      const untestedProjects = [{ fullPath: '/foo', fullName: 'Foo' }];

      factory({ untestedProjects });

      expect(untestedProjectsTabContent().element).toMatchSnapshot();
    });
  });
});
