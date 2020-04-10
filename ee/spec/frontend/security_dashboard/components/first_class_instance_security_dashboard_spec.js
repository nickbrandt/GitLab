import { shallowMount } from '@vue/test-utils';
import SecurityDashboardLayout from 'ee/security_dashboard/components/security_dashboard_layout.vue';
import FirstClassInstanceDashboard from 'ee/security_dashboard/components/first_class_instance_security_dashboard.vue';
import FirstClassInstanceVulnerabilities from 'ee/security_dashboard/components/first_class_instance_security_dashboard_vulnerabilities.vue';
import VulnerabilitySeverity from 'ee/security_dashboard/components/vulnerability_severity.vue';

describe('First Class Instance Dashboard Component', () => {
  let wrapper;

  const dashboardDocumentation = 'dashboard-documentation';
  const emptyStateSvgPath = 'empty-state-path';
  const vulnerableProjectsEndpoint = '/vulnerable/projects';

  const findInstanceVulnerabilities = () => wrapper.find(FirstClassInstanceVulnerabilities);
  const findVulnerabilitySeverity = () => wrapper.find(VulnerabilitySeverity);

  const createWrapper = () => {
    return shallowMount(FirstClassInstanceDashboard, {
      propsData: {
        dashboardDocumentation,
        emptyStateSvgPath,
        vulnerableProjectsEndpoint,
      },
      stubs: {
        SecurityDashboardLayout,
      },
    });
  };

  beforeEach(() => {
    wrapper = createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render correctly', () => {
    expect(findInstanceVulnerabilities().props()).toEqual({
      dashboardDocumentation,
      emptyStateSvgPath,
    });
  });

  it('displays the vulnerability severity in an aside', () => {
    expect(findVulnerabilitySeverity().exists()).toBe(true);
  });
});
