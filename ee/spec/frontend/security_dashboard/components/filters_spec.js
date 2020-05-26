import Vuex from 'vuex';
import Filters from 'ee/security_dashboard/components/filters.vue';
import createStore from 'ee/security_dashboard/store';
import { mount, createLocalVue } from '@vue/test-utils';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Filter component', () => {
  let wrapper;
  let store;

  const findReportTypeFilter = () => wrapper.find('.js-filter-report_type');

  const createWrapper = (props = {}) => {
    wrapper = mount(Filters, {
      localVue,
      store,
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('severity', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should display all filters', () => {
      expect(wrapper.findAll('.js-filter')).toHaveLength(3);
    });

    it('should display "Hide dismissed vulnerabilities" toggle', () => {
      expect(wrapper.findAll('.js-toggle')).toHaveLength(1);
    });
  });

  describe('Report type', () => {
    it.each`
      dastProps                                                  | string
      ${{ vulnerabilitiesCount: 0, scannedResourcesCount: 123 }} | ${'(0 vulnerabilities, 123 urls scanned)'}
      ${{ vulnerabilitiesCount: 481, scannedResourcesCount: 0 }} | ${'(481 vulnerabilities, 0 urls scanned)'}
      ${{ vulnerabilitiesCount: 1, scannedResourcesCount: 1 }}   | ${'(1 vulnerability, 1 url scanned)'}
      ${{ vulnerabilitiesCount: 321 }}                           | ${'(321 vulnerabilities)'}
      ${{ scannedResourcesCount: 890 }}                          | ${'(890 urls scanned)'}
      ${{ vulnerabilitiesCount: 0 }}                             | ${'(0 vulnerabilities)'}
      ${{ scannedResourcesCount: 0 }}                            | ${'(0 urls scanned)'}
    `('shows security report summary $string', ({ dastProps, string }) => {
      createWrapper({
        securityReportSummary: {
          dast: dastProps,
        },
      });
      expect(findReportTypeFilter().text()).toContain(string);
    });
  });
});
