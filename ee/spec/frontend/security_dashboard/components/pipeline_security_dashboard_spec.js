import Vuex from 'vuex';
import { GlEmptyState } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import PipelineSecurityDashboard from 'ee/security_dashboard/components/pipeline_security_dashboard.vue';
import SecurityDashboard from 'ee/security_dashboard/components/security_dashboard_vuex.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

const dashboardDocumentation = '/help/docs';
const emptyStateSvgPath = '/svgs/empty/svg';
const pipelineId = 1234;
const projectId = 5678;
const sourceBranch = 'feature-branch-1';
const vulnerabilitiesEndpoint = '/vulnerabilities';
const vulnerabilityFeedbackHelpPath = '/vulnerabilities_feedback_help';
const loadingErrorIllustrations = {
  401: '/401.svg',
  403: '/403.svg',
};

describe('Pipeline Security Dashboard component', () => {
  let store;
  let wrapper;

  const factory = options => {
    store = new Vuex.Store({
      modules: {
        vulnerabilities: {
          namespaced: true,
          actions: {
            setSourceBranch() {},
          },
        },
      },
    });
    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMount(PipelineSecurityDashboard, {
      localVue,
      store,
      data() {
        return { securityReportSummary: {} };
      },
      propsData: {
        dashboardDocumentation,
        emptyStateSvgPath,
        pipelineId,
        projectId,
        sourceBranch,
        vulnerabilitiesEndpoint,
        vulnerabilityFeedbackHelpPath,
        loadingErrorIllustrations,
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
        ['vulnerabilities/setSourceBranch', sourceBranch],
      ]);
    });

    it('renders the security dashboard', () => {
      const dashboard = wrapper.find(SecurityDashboard);
      expect(dashboard.exists()).toBe(true);
      expect(dashboard.props()).toMatchObject({
        lockToProject: { id: projectId },
        pipelineId,
        vulnerabilitiesEndpoint,
        vulnerabilityFeedbackHelpPath,
      });
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

      expect(emptyState.attributes('title')).toBe('No vulnerabilities found for this pipeline');
    });
  });
});
