import { shallowMount } from '@vue/test-utils';
import { GlAlert, GlTable, GlEmptyState, GlIntersectionObserver } from '@gitlab/ui';
import FirstClassGroupVulnerabilities from 'ee/security_dashboard/components/first_class_group_security_dashboard_vulnerabilities.vue';
import VulnerabilityList from 'ee/security_dashboard/components/vulnerability_list.vue';
import { generateVulnerabilities } from './mock_data';

describe('First Class Group Dashboard Vulnerabilities Component', () => {
  let wrapper;

  const groupFullPath = 'group-full-path';

  const findIntersectionObserver = () => wrapper.find(GlIntersectionObserver);
  const findVulnerabilities = () => wrapper.find(VulnerabilityList);
  const findAlert = () => wrapper.find(GlAlert);

  const createWrapper = ({ $apollo, stubs }) => {
    return shallowMount(FirstClassGroupVulnerabilities, {
      propsData: {
        groupFullPath,
      },
      stubs,
      mocks: {
        $apollo,
        fetchNextPage: () => {},
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when the query is loading', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        $apollo: {
          queries: { vulnerabilities: { loading: true } },
        },
      });
    });

    it('passes down isLoading correctly', () => {
      expect(findVulnerabilities().props()).toEqual({
        filters: {},
        isLoading: true,
        shouldShowIdentifier: false,
        shouldShowReportType: false,
        shouldShowSelection: true,
        shouldShowProjectNamespace: true,
        vulnerabilities: [],
      });
    });
  });

  describe('when the query returned an error status', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        $apollo: {
          queries: { vulnerabilities: { loading: false } },
        },
        stubs: {
          GlAlert,
        },
      });

      wrapper.setData({
        errorLoadingVulnerabilities: true,
      });
    });

    it('displays the alert', () => {
      expect(findAlert().text()).toBe(
        'Error fetching the vulnerability list. Please check your network connection and try again.',
      );
    });

    it('should have an alert that is dismissable', () => {
      const alert = findAlert();
      alert.find('button').trigger('click');
      return wrapper.vm.$nextTick(() => {
        expect(alert.exists()).toBe(false);
      });
    });

    it('does not display the vulnerabilities', () => {
      expect(findVulnerabilities().exists()).toBe(false);
    });
  });

  describe('when the query is loaded and we have results', () => {
    const vulnerabilities = generateVulnerabilities();

    beforeEach(() => {
      wrapper = createWrapper({
        $apollo: {
          queries: { vulnerabilities: { loading: false } },
        },
        stubs: {
          VulnerabilityList,
          GlTable,
          GlEmptyState,
        },
      });

      wrapper.setData({
        vulnerabilities,
      });
    });

    it('passes down properties correctly', () => {
      expect(findVulnerabilities().props()).toEqual({
        filters: {},
        isLoading: false,
        shouldShowIdentifier: false,
        shouldShowReportType: false,
        shouldShowSelection: true,
        shouldShowProjectNamespace: true,
        vulnerabilities,
      });
    });
  });

  describe('when there is more than a page of vulnerabilities', () => {
    const vulnerabilities = generateVulnerabilities();

    beforeEach(() => {
      wrapper = createWrapper({
        $apollo: {
          queries: { vulnerabilities: { loading: false } },
        },
      });

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
});
