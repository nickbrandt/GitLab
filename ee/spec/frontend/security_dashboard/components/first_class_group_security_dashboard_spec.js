import { shallowMount } from '@vue/test-utils';
import SecurityDashboardLayout from 'ee/security_dashboard/components/security_dashboard_layout.vue';
import FirstClassGroupDashboard from 'ee/security_dashboard/components/first_class_group_security_dashboard.vue';
import FirstClassGroupVulnerabilities from 'ee/security_dashboard/components/first_class_group_security_dashboard_vulnerabilities.vue';
import VulnerabilitySeverity from 'ee/security_dashboard/components/vulnerability_severity.vue';

describe('First Class Group Dashboard Component', () => {
  let wrapper;

  const dashboardDocumentation = 'dashboard-documentation';
  const emptyStateSvgPath = 'empty-state-path';
  const groupFullPath = 'group-full-path';
  const vulnerableProjectsEndpoint = '/vulnerable/projects';

  const findGroupVulnerabilities = () => wrapper.find(FirstClassGroupVulnerabilities);
  const findVulnerabilitySeverity = () => wrapper.find(VulnerabilitySeverity);

  const createWrapper = () => {
    return shallowMount(FirstClassGroupDashboard, {
      propsData: {
        dashboardDocumentation,
        emptyStateSvgPath,
        groupFullPath,
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
    expect(findGroupVulnerabilities().props()).toEqual({
      dashboardDocumentation,
      emptyStateSvgPath,
      groupFullPath,
    });
  });

  it('displays the vulnerability severity in an aside', () => {
    expect(findVulnerabilitySeverity().exists()).toBe(true);
  });
});
