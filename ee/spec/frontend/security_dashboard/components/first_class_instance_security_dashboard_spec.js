import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import SecurityDashboardLayout from 'ee/security_dashboard/components/security_dashboard_layout.vue';
import FirstClassInstanceDashboard from 'ee/security_dashboard/components/first_class_instance_security_dashboard.vue';
import FirstClassInstanceVulnerabilities from 'ee/security_dashboard/components/first_class_instance_security_dashboard_vulnerabilities.vue';
import VulnerabilitySeverity from 'ee/security_dashboard/components/first_class_vulnerability_severities.vue';
import VulnerabilityChart from 'ee/security_dashboard/components/first_class_vulnerability_chart.vue';
import CsvExportButton from 'ee/security_dashboard/components/csv_export_button.vue';
import Filters from 'ee/security_dashboard/components/first_class_vulnerability_filters.vue';
import ProjectManager from 'ee/security_dashboard/components/first_class_project_manager/project_manager.vue';
import DashboardNotConfigured from 'ee/security_dashboard/components/empty_states/instance_dashboard_not_configured.vue';

describe('First Class Instance Dashboard Component', () => {
  let wrapper;

  const defaultMocks = { $apollo: { queries: { projects: { loading: false } } } };

  const vulnerableProjectsEndpoint = '/vulnerable/projects';
  const vulnerabilitiesExportEndpoint = '/vulnerabilities/exports';

  const findInstanceVulnerabilities = () => wrapper.find(FirstClassInstanceVulnerabilities);
  const findVulnerabilitySeverity = () => wrapper.find(VulnerabilitySeverity);
  const findVulnerabilityChart = () => wrapper.find(VulnerabilityChart);
  const findCsvExportButton = () => wrapper.find(CsvExportButton);
  const findProjectManager = () => wrapper.find(ProjectManager);
  const findEmptyState = () => wrapper.find(DashboardNotConfigured);
  const findFilters = () => wrapper.find(Filters);

  const createWrapper = ({ data = {}, stubs }) => {
    return shallowMount(FirstClassInstanceDashboard, {
      data() {
        return { ...data };
      },
      mocks: { ...defaultMocks },
      propsData: {
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
        data: {
          projects: [{ id: 1 }, { id: 2 }],
        },
      });
    });

    it('should render the vulnerabilities', () => {
      expect(findInstanceVulnerabilities().props()).toEqual({
        filters: {},
      });
    });

    it('has filters', () => {
      expect(findFilters().exists()).toBe(true);
    });

    it('does not pass down a groupFullPath to the vulnerability chart', () => {
      expect(findVulnerabilityChart().props('groupFullPath')).toBeUndefined();
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
        data: {
          isManipulatingProjects: false,
          stubs: {
            DashboardNotConfigured,
            GlButton,
          },
        },
      });
    });

    it('renders the empty state', () => {
      expect(findEmptyState().props()).toEqual({});
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
