import { shallowMount } from '@vue/test-utils';
import FirstClassInstanceDashboard from 'ee/security_dashboard/components/first_class_instance_security_dashboard.vue';
import FirstClassInstanceVulnerabilities from 'ee/security_dashboard/components/first_class_instance_security_dashboard_vulnerabilities.vue';

describe('First Class Group Dashboard Component', () => {
  let wrapper;

  const dashboardDocumentation = 'dashboard-documentation';
  const emptyStateSvgPath = 'empty-state-path';

  const findGroupVulnerabilities = () => wrapper.find(FirstClassInstanceVulnerabilities);

  const createWrapper = () => {
    return shallowMount(FirstClassInstanceDashboard, {
      propsData: {
        dashboardDocumentation,
        emptyStateSvgPath,
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
    });
  });
});
