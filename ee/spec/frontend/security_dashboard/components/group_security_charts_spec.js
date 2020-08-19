import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'jest/helpers/test_constants';
import GroupSecurityCharts from 'ee/security_dashboard/components/group_security_charts.vue';
import SecurityChartsLayout from 'ee/security_dashboard/components/security_charts_layout.vue';
import VulnerabilityChart from 'ee/security_dashboard/components/first_class_vulnerability_chart.vue';
import VulnerabilitySeverities from 'ee/security_dashboard/components/first_class_vulnerability_severities.vue';

jest.mock('ee/security_dashboard/graphql/group_vulnerability_history.query.graphql', () => ({}));

describe('Group Security Charts component', () => {
  let wrapper;

  const groupFullPath = `${TEST_HOST}/group/5`;

  const findSecurityChartsLayoutComponent = () => wrapper.find(SecurityChartsLayout);
  const findVulnerabilityChart = () => wrapper.find(VulnerabilityChart);
  const findVulnerabilitySeverities = () => wrapper.find(VulnerabilitySeverities);

  const createWrapper = () => {
    wrapper = shallowMount(GroupSecurityCharts, {
      propsData: { groupFullPath },
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
    const vulnerabilitySeverities = findVulnerabilitySeverities();

    expect(securityChartsLayout.exists()).toBe(true);
    expect(vulnerabilityChart.props()).toEqual({ query: {}, groupFullPath });
    expect(vulnerabilitySeverities.exists()).toBe(true);
    expect(vulnerabilitySeverities.props().groupFullPath).toEqual(groupFullPath);
  });
});
