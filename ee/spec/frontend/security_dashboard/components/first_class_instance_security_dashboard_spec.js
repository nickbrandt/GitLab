import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlEmptyState, GlButton } from '@gitlab/ui';
import SecurityDashboardLayout from 'ee/security_dashboard/components/security_dashboard_layout.vue';
import FirstClassInstanceDashboard from 'ee/security_dashboard/components/first_class_instance_security_dashboard.vue';
import FirstClassInstanceVulnerabilities from 'ee/security_dashboard/components/first_class_instance_security_dashboard_vulnerabilities.vue';
import VulnerabilitySeverity from 'ee/security_dashboard/components/vulnerability_severity.vue';
import VulnerabilityChart from 'ee/security_dashboard/components/first_class_vulnerability_chart.vue';
import CsvExportButton from 'ee/security_dashboard/components/csv_export_button.vue';
import Filters from 'ee/security_dashboard/components/first_class_vulnerability_filters.vue';
import ProjectManager from 'ee/security_dashboard/components/project_manager.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('First Class Instance Dashboard Component', () => {
  let wrapper;
  let store;

  const dashboardDocumentation = 'dashboard-documentation';
  const emptyStateSvgPath = 'empty-state-path';
  const vulnerableProjectsEndpoint = '/vulnerable/projects';
  const vulnerabilitiesExportEndpoint = '/vulnerabilities/exports';
  const projectAddEndpoint = 'projectAddEndpoint';
  const projectListEndpoint = 'projectListEndpoint';

  const findInstanceVulnerabilities = () => wrapper.find(FirstClassInstanceVulnerabilities);
  const findVulnerabilitySeverity = () => wrapper.find(VulnerabilitySeverity);
  const findVulnerabilityChart = () => wrapper.find(VulnerabilityChart);
  const findCsvExportButton = () => wrapper.find(CsvExportButton);
  const findProjectManager = () => wrapper.find(ProjectManager);
  const findEmptyState = () => wrapper.find(GlEmptyState);
  const findFilters = () => wrapper.find(Filters);

  const createWrapper = ({ isUpdatingProjects = false, projects = [], stubs }) => {
    store = new Vuex.Store({
      modules: {
        projectSelector: {
          namespaced: true,
          actions: {
            fetchProjects() {},
            setProjectEndpoints() {},
          },
          getters: {
            isUpdatingProjects: jest.fn().mockReturnValue(isUpdatingProjects),
          },
          state: {
            projects,
          },
        },
      },
    });

    return shallowMount(FirstClassInstanceDashboard, {
      localVue,
      store,
      propsData: {
        dashboardDocumentation,
        emptyStateSvgPath,
        projectAddEndpoint,
        projectListEndpoint,
        vulnerableProjectsEndpoint,
        vulnerabilitiesExportEndpoint,
      },
      stubs: {
        ...stubs,
        SecurityDashboardLayout,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when initialized', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        isUpdatingProjects: false,
        projects: [{ id: 1 }, { id: 2 }],
      });
    });

    it('should render the vulnerabilities', () => {
      expect(findInstanceVulnerabilities().props()).toEqual({
        dashboardDocumentation,
        emptyStateSvgPath,
        filters: {},
      });
    });

    it('has filters', () => {
      expect(findFilters().exists()).toBe(true);
    });

    it('does not pass down a groupFullPath to the vulnerability chart', () => {
      expect(findVulnerabilityChart().props('groupFullPath')).toBeUndefined();
    });

    it('responds to the projectFetch event', () => {
      const projects = [{ id: 1, name: 'GitLab Org' }];
      findInstanceVulnerabilities().vm.$listeners.projectFetch(projects);
      return wrapper.vm.$nextTick(() => {
        expect(findFilters().props('projects')).toEqual(projects);
      });
    });

    it('responds to the filterChange event', () => {
      const filters = { severity: 'critical' };
      findFilters().vm.$listeners.filterChange(filters);
      return wrapper.vm.$nextTick(() => {
        expect(wrapper.vm.filters).toEqual(filters);
        expect(findInstanceVulnerabilities().props('filters')).toEqual(filters);
      });
    });

    it('displays the vulnerability severity in an aside', () => {
      expect(findVulnerabilitySeverity().exists()).toBe(true);
    });

    it('displays the csv export button', () => {
      expect(findCsvExportButton().props('vulnerabilitiesExportEndpoint')).toBe(
        vulnerabilitiesExportEndpoint,
      );
    });
  });

  describe('when uninitialized', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        isUpdatingProjects: false,
        stubs: {
          GlEmptyState,
          GlButton,
        },
      });
    });

    it('renders the empty state', () => {
      expect(findEmptyState().props('title')).toBe('Add a project to your dashboard');
    });

    it('does not render the vulnerability list', () => {
      expect(findInstanceVulnerabilities().exists()).toBe(false);
    });

    it('has no filters', () => {
      expect(findFilters().exists()).toBe(false);
    });

    it('does not display the vulnerability severity in an aside', () => {
      expect(findVulnerabilitySeverity().exists()).toBe(false);
    });

    it('displays the project manager when the button in empty state is clicked', () => {
      expect(findProjectManager().exists()).toBe(false);
      wrapper.find(GlButton).vm.$emit('click');
      return wrapper.vm.$nextTick(() => {
        expect(findProjectManager().exists()).toBe(true);
      });
    });
  });

  describe('always', () => {
    beforeEach(() => {
      wrapper = createWrapper({});
    });

    it('has the security dashboard title', () => {
      expect(wrapper.find('.page-title').text()).toBe('Security Dashboard');
    });

    it('displays the project manager when the edit dashboard button is clicked', () => {
      expect(findProjectManager().exists()).toBe(false);
      wrapper.find(GlButton).vm.$emit('click');
      return wrapper.vm.$nextTick(() => {
        expect(findProjectManager().exists()).toBe(true);
      });
    });
  });
});
