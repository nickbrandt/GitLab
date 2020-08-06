import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'jest/helpers/test_constants';
import GroupSecurityCharts from 'ee/security_dashboard/components/group_security_charts.vue';
import SecurityChartsLayout from 'ee/security_dashboard/components/security_charts_layout.vue';
import VulnerabilityChart from 'ee/security_dashboard/components/first_class_vulnerability_chart.vue';
import VulnerabilitySeverity from 'ee/security_dashboard/components/vulnerability_severity.vue';

jest.mock('ee/security_dashboard/graphql/group_vulnerability_history.query.graphql', () => ({}));

describe('Group Security Charts component', () => {
  let wrapper;

  const groupFullPath = `${TEST_HOST}/group/5`;
  const vulnerableProjectsEndpoint = `${TEST_HOST}/group/5/projects`;

  const findSecurityChartsLayoutComponent = () => wrapper.find(SecurityChartsLayout);
  const findVulnerabilityChart = () => wrapper.find(VulnerabilityChart);
  const findVulnerabilitySeverity = () => wrapper.find(VulnerabilitySeverity);

  const createWrapper = () => {
    wrapper = shallowMount(GroupSecurityCharts, {
      propsData: { groupFullPath, vulnerableProjectsEndpoint },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders the default page', () => {
    const securityChartsLayout = findSecurityChartsLayoutComponent();
    const vulnerabilityChart = findVulnerabilityChart();
    const vulnerabilitySeverity = findVulnerabilitySeverity();

    expect(securityChartsLayout.exists()).toBe(true);
    expect(vulnerabilityChart.props()).toEqual({ query: {}, groupFullPath });
    expect(vulnerabilitySeverity.props()).toEqual({
      endpoint: vulnerableProjectsEndpoint,
      helpPagePath: '',
    });
  });
});
