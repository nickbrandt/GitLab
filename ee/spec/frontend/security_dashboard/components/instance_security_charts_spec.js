import { shallowMount } from '@vue/test-utils';
import InstanceSecurityCharts from 'ee/security_dashboard/components/instance_security_charts.vue';
import VulnerabilityChart from 'ee/security_dashboard/components/first_class_vulnerability_chart.vue';
import VulnerabilitySeverities from 'ee/security_dashboard/components/first_class_vulnerability_severities.vue';
import SecurityChartsLayout from 'ee/security_dashboard/components/security_charts_layout.vue';
import vulnerabilityGradesQuery from 'ee/security_dashboard/graphql/instance_vulnerability_grades.query.graphql';
import vulnerabilityHistoryQuery from 'ee/security_dashboard/graphql/instance_vulnerability_history.query.graphql';

jest.mock('ee/security_dashboard/graphql/instance_vulnerability_grades.query.graphql', () => ({
  mockGrades: true,
}));
jest.mock('ee/security_dashboard/graphql/instance_vulnerability_history.query.graphql', () => ({
  mockHistory: true,
}));

describe('Instance Security Charts component', () => {
  let wrapper;

  const findSecurityChartsLayoutComponent = () => wrapper.find(SecurityChartsLayout);
  const findVulnerabilityChart = () => wrapper.find(VulnerabilityChart);
  const findVulnerabilitySeverities = () => wrapper.find(VulnerabilitySeverities);

  const createWrapper = () => {
    wrapper = shallowMount(InstanceSecurityCharts, {});
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
    expect(vulnerabilityChart.props()).toEqual({ query: vulnerabilityHistoryQuery });
    expect(vulnerabilitySeverities.exists()).toBe(true);
    expect(vulnerabilitySeverities.props()).toEqual({
      query: vulnerabilityGradesQuery,
      groupFullPath: undefined,
      helpPagePath: '',
    });
  });
});
