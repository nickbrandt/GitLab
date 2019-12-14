import Vuex from 'vuex';
import { GlEmptyState } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import GroupSecurityDashboard from 'ee/security_dashboard/components/group_security_dashboard.vue';
import SecurityDashboard from 'ee/security_dashboard/components/app.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

const dashboardDocumentation = '/help/docs';
const emptyStateSvgPath = '/svgs/empty/svg';
const projectsEndpoint = '/projects';
const vulnerabilitiesEndpoint = '/vulnerabilities';
const vulnerabilitiesCountEndpoint = '/vulnerabilities_summary';
const vulnerabilitiesHistoryEndpoint = '/vulnerabilities_history';
const vulnerabilityFeedbackHelpPath = '/vulnerabilities_feedback_help';
const vulnerableProjectsEndpoint = '/vulnerable_projects';

describe('Group Security Dashboard component', () => {
  let store;
  let wrapper;

  const factory = options => {
    store = new Vuex.Store({
      modules: {
        projects: {
          namespaced: true,
          actions: {
            fetchProjects() {},
            setProjectsEndpoint() {},
          },
        },
      },
    });
    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMount(GroupSecurityDashboard, {
      localVue,
      store,
      sync: false,
      propsData: {
        dashboardDocumentation,
        emptyStateSvgPath,
        projectsEndpoint,
        vulnerabilitiesEndpoint,
        vulnerabilitiesCountEndpoint,
        vulnerabilitiesHistoryEndpoint,
        vulnerabilityFeedbackHelpPath,
        vulnerableProjectsEndpoint,
      },
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('on creation', () => {
    beforeEach(() => {
      factory();
    });

    it('dispatches the expected actions', () => {
      expect(store.dispatch.mock.calls).toEqual([
        ['projects/setProjectsEndpoint', projectsEndpoint],
        ['projects/fetchProjects', undefined],
      ]);
    });

    it('renders the security dashboard', () => {
      const dashboard = wrapper.find(SecurityDashboard);
      expect(dashboard.exists()).toBe(true);
      expect(dashboard.props()).toEqual(
        expect.objectContaining({
          vulnerabilitiesEndpoint,
          vulnerabilitiesCountEndpoint,
          vulnerabilitiesHistoryEndpoint,
          vulnerabilityFeedbackHelpPath,
          vulnerableProjectsEndpoint,
        }),
      );
    });
  });

  describe('with a stubbed dashboard for slot testing', () => {
    beforeEach(() => {
      factory({
        stubs: {
          'security-dashboard': { template: '<div><slot name="emptyState"></slot></div>' },
        },
      });
    });

    it('renders empty state component with correct props', () => {
      const emptyState = wrapper.find(GlEmptyState);

      expect(emptyState.attributes('title')).toBe('No vulnerabilities found for this group');
    });
  });
});
