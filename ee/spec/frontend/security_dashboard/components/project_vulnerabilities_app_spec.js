import { GlAlert, GlIntersectionObserver } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ProjectVulnerabilitiesApp from 'ee/security_dashboard/components/project_vulnerabilities.vue';
import VulnerabilityList from 'ee/security_dashboard/components/vulnerability_list.vue';
import { generateVulnerabilities } from './mock_data';

describe('Vulnerabilities app component', () => {
  let wrapper;
  const apolloMock = {
    queries: { vulnerabilities: { loading: true } },
  };

  const createWrapper = ({ props = {}, $apollo = apolloMock } = {}, options = {}) => {
    return shallowMount(ProjectVulnerabilitiesApp, {
      propsData: {
        dashboardDocumentation: '#',
        emptyStateSvgPath: '#',
        projectFullPath: '#',
        ...props,
      },
      mocks: {
        $apollo,
        fetchNextPage: () => {},
      },
      ...options,
    });
  };

  const findIntersectionObserver = () => wrapper.find(GlIntersectionObserver);
  const findAlert = () => wrapper.find(GlAlert);
  const findVulnerabilityList = () => wrapper.find(VulnerabilityList);

  beforeEach(() => {
    wrapper = createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when the vulnerabilities are loading', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should be in the loading state', () => {
      expect(findVulnerabilityList().props().isLoading).toBe(true);
    });
  });

  describe('with some vulnerabilities', () => {
    let vulnerabilities;

    beforeEach(() => {
      createWrapper();

      vulnerabilities = generateVulnerabilities();
      wrapper.setData({
        vulnerabilities,
      });
    });

    it('should not be in the loading state', () => {
      expect(findVulnerabilityList().props().isLoading).toBe(false);
    });

    it('should pass the vulnerabilities to the vulnerabilities list', () => {
      expect(findVulnerabilityList().props().vulnerabilities).toEqual(vulnerabilities);
    });

    it('should not render the observer component', () => {
      expect(findIntersectionObserver().exists()).toBe(false);
    });

    it('should not render the alert', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('with more than a page of vulnerabilities', () => {
    let vulnerabilities;

    beforeEach(() => {
      createWrapper();

      vulnerabilities = generateVulnerabilities();
      wrapper.setData({
        vulnerabilities,
        pageInfo: {
          hasNextPage: true,
        },
      });
    });

    it('should render the observer component', () => {
      expect(findIntersectionObserver().exists()).toBe(true);
    });
  });

  describe("when there's a loading error", () => {
    beforeEach(() => {
      createWrapper();
      wrapper.setData({ errorLoadingVulnerabilities: true });
    });

    it('should render the alert', () => {
      expect(findAlert().exists()).toBe(true);
    });
  });
});
