import { shallowMount } from '@vue/test-utils';
import { GlBanner } from '@gitlab/ui';
import Cookies from 'js-cookie';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'helpers/test_constants';
import FirstClassProjectSecurityDashboard, {
  BANNER_COOKIE_KEY,
} from 'ee/security_dashboard/components/first_class_project_security_dashboard.vue';
import Filters from 'ee/security_dashboard/components/first_class_vulnerability_filters.vue';
import SecurityDashboardLayout from 'ee/security_dashboard/components/security_dashboard_layout.vue';
import ProjectVulnerabilitiesApp from 'ee/vulnerabilities/components/project_vulnerabilities_app.vue';
import ReportsNotConfigured from 'ee/security_dashboard/components/empty_states/reports_not_configured.vue';
import CsvExportButton from 'ee/security_dashboard/components/csv_export_button.vue';

const props = {
  dashboardDocumentation: '/help/docs',
  emptyStateSvgPath: '/svgs/empty/svg',
  projectFullPath: '/group/project',
  securityDashboardHelpPath: '/security/dashboard/help-path',
  vulnerabilitiesExportEndpoint: '/vulnerabilities/exports',
  userCalloutId: 'standalone_vulnerabilities_introduction_banner',
  userCalloutsPath: `${TEST_HOST}/user_callouts`,
  showIntroductionBanner: false,
};
const filters = { foo: 'bar' };

describe('First class Project Security Dashboard component', () => {
  let wrapper;

  const findFilters = () => wrapper.find(Filters);
  const findVulnerabilities = () => wrapper.find(ProjectVulnerabilitiesApp);
  const findUnconfiguredState = () => wrapper.find(ReportsNotConfigured);
  const findCsvExportButton = () => wrapper.find(CsvExportButton);
  const findIntroductionBanner = () => wrapper.find(GlBanner);

  const createComponent = options => {
    wrapper = shallowMount(FirstClassProjectSecurityDashboard, {
      propsData: {
        ...props,
        ...options.props,
      },
      stubs: { SecurityDashboardLayout, GlBanner },
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('on render when pipeline has data', () => {
    beforeEach(() => {
      createComponent({ props: { hasPipelineData: true } });
    });

    it('should render the vulnerabilities', () => {
      expect(findVulnerabilities().exists()).toBe(true);
    });

    it('should pass down the %s prop to the vulnerabilities', () => {
      expect(findVulnerabilities().props('dashboardDocumentation')).toBe(
        props.dashboardDocumentation,
      );
      expect(findVulnerabilities().props('emptyStateSvgPath')).toBe(props.emptyStateSvgPath);
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

  describe('when user visits for the first time', () => {
    let mockAxios;

    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
      mockAxios.onPost(props.userCalloutsPath, { feature_name: props.userCalloutId }).reply(200);
      createComponent({ props: { hasPipelineData: true, showIntroductionBanner: true } });
    });

    afterEach(() => {
      mockAxios.restore();
    });

    it('displays a banner which the title highlights the new functionality', () => {
      expect(findIntroductionBanner().text()).toContain('Introducing standalone vulnerabilities');
    });

    it('displays a banner which the content describes the new functionality', () => {
      expect(findIntroductionBanner().text()).toContain(
        'Each vulnerability now has a unique page that can be directly linked to, shared, referenced, and tracked as the single source of truth. Vulnerability occurrences also persist across scanner runs, which improves tracking and visibility and reduces duplicates between scans.',
      );
    });

    it('links the banner to the proper documentation page', () => {
      expect(findIntroductionBanner().props('buttonLink')).toBe(props.dashboardDocumentation);
    });

    it('hides the banner when the user clicks on the dismiss button', () => {
      findIntroductionBanner()
        .find('button.close')
        .trigger('click');

      return waitForPromises().then(() => {
        expect(findIntroductionBanner().exists()).toBe(false);
        expect(mockAxios.history.post).toHaveLength(1);
      });
    });
  });

  describe('when user already dismissed the banner in the past', () => {
    beforeEach(() => {
      Cookies.set(BANNER_COOKIE_KEY, 'true');
      createComponent({ props: { hasPipelineData: true, showIntroductionBanner: true } });
    });

    afterEach(() => {
      Cookies.remove(BANNER_COOKIE_KEY);
    });

    it('does not display the banner despite showIntroductionBanner is true', () => {
      expect(findIntroductionBanner().exists()).toBe(false);
    });
  });

  describe('with filter data', () => {
    beforeEach(() => {
      createComponent({
        props: {
          hasPipelineData: true,
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

  describe('when pipeline has no data', () => {
    beforeEach(() => {
      createComponent({
        props: {
          hasPipelineData: false,
        },
      });
    });

    it('displays the unconfigured state', () => {
      expect(findUnconfiguredState().exists()).toBe(true);
    });
  });
});
