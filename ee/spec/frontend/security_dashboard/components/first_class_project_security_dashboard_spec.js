import { shallowMount } from '@vue/test-utils';
import { GlBanner } from '@gitlab/ui';
import FirstClassProjectSecurityDashboard from 'ee/security_dashboard/components/first_class_project_security_dashboard.vue';
import Filters from 'ee/security_dashboard/components/first_class_vulnerability_filters.vue';
import SecurityDashboardLayout from 'ee/security_dashboard/components/security_dashboard_layout.vue';
import ProjectVulnerabilitiesApp from 'ee/security_dashboard/components/project_vulnerabilities.vue';
import ReportsNotConfigured from 'ee/security_dashboard/components/empty_states/reports_not_configured.vue';
import CsvExportButton from 'ee/security_dashboard/components/csv_export_button.vue';

const props = {
  notEnabledScannersHelpPath: '/help/docs/',
  noPipelineRunScannersHelpPath: '/new/pipeline',
  projectFullPath: '/group/project',
  securityDashboardHelpPath: '/security/dashboard/help-path',
  vulnerabilitiesExportEndpoint: '/vulnerabilities/exports',
};

const provide = {
  dashboardDocumentation: '/help/docs',
  emptyStateSvgPath: '/svgs/empty/svg',
};

const filters = { foo: 'bar' };

describe('First class Project Security Dashboard component', () => {
  let wrapper;

  const findFilters = () => wrapper.find(Filters);
  const findVulnerabilities = () => wrapper.find(ProjectVulnerabilitiesApp);
  const findUnconfiguredState = () => wrapper.find(ReportsNotConfigured);
  const findCsvExportButton = () => wrapper.find(CsvExportButton);

  const createComponent = options => {
    wrapper = shallowMount(FirstClassProjectSecurityDashboard, {
      propsData: {
        ...props,
        ...options.props,
      },
      provide,
      stubs: { SecurityDashboardLayout, GlBanner },
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('on render when there are vulnerabilities', () => {
    beforeEach(() => {
      createComponent({ props: { hasVulnerabilities: true } });
    });

    it('should render the vulnerabilities', () => {
      expect(findVulnerabilities().exists()).toBe(true);
    });

    it('should pass down the "projectFullPath" prop to the vulnerabilities', () => {
      expect(findVulnerabilities().props('projectFullPath')).toBe(props.projectFullPath);
    });

    it('should render the filters component', () => {
      expect(findFilters().exists()).toBe(true);
    });

    it('does not display the unconfigured state', () => {
      expect(findUnconfiguredState().exists()).toBe(false);
    });

    it('should display the csv export button', () => {
      expect(findCsvExportButton().props('vulnerabilitiesExportEndpoint')).toEqual(
        props.vulnerabilitiesExportEndpoint,
      );
    });
  });

  describe('with filter data', () => {
    beforeEach(() => {
      createComponent({
        props: {
          hasVulnerabilities: true,
        },
        data() {
          return { filters };
        },
      });
    });

    it('should pass the filter data down to the vulnerabilities', () => {
      expect(findVulnerabilities().props().filters).toEqual(filters);
    });
  });

  describe('when there is no vulnerability', () => {
    beforeEach(() => {
      createComponent({
        props: {
          hasVulnerabilities: false,
        },
      });
    });

    it('displays the unconfigured state', () => {
      expect(findUnconfiguredState().exists()).toBe(true);
    });
  });
});
