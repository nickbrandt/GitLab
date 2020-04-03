import { shallowMount } from '@vue/test-utils';
import FirstClassProjectSecurityDashboard from 'ee/security_dashboard/components/first_class_project_security_dashboard.vue';
import Filters from 'ee/security_dashboard/components/first_class_vulnerability_filters.vue';
import SecurityDashboardLayout from 'ee/security_dashboard/components/security_dashboard_layout.vue';
import ProjectVulnerabilitiesApp from 'ee/vulnerabilities/components/project_vulnerabilities_app.vue';

const drilledProps = {
  dashboardDocumentation: '/help/docs',
  emptyStateSvgPath: '/svgs/empty/svg',
  projectFullPath: '/group/project',
};
const filters = { foo: 'bar' };

describe('First class Project Security Dashboard component', () => {
  let wrapper;

  const findFilters = () => wrapper.find(Filters);
  const findVulnerabilities = () => wrapper.find(ProjectVulnerabilitiesApp);

  const createComponent = options => {
    wrapper = shallowMount(FirstClassProjectSecurityDashboard, {
      propsData: drilledProps,
      stubs: { SecurityDashboardLayout },
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('on render', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should render the vulnerabilities', () => {
      expect(findVulnerabilities().exists()).toBe(true);
    });

    it.each(Object.entries(drilledProps))(
      'should pass down the %s prop to the vulnerabilities',
      (key, value) => {
        expect(findVulnerabilities().props(key)).toBe(value);
      },
    );

    it('should render the filters component', () => {
      expect(findFilters().exists()).toBe(true);
    });
  });

  describe('with filter data', () => {
    beforeEach(() => {
      createComponent({
        data() {
          return { filters };
        },
      });
    });

    it('should pass the filter data down to the vulnerabilities', () => {
      expect(findVulnerabilities().props().filters).toEqual(filters);
    });
  });
});
