import Vue from 'vue';
import component from 'ee/security_dashboard/components/filters.vue';
import createStore from 'ee/security_dashboard/store';
import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';

describe('Filter component', () => {
  let vm;
  const store = createStore();
  const Component = Vue.extend(component);

  afterEach(() => {
    vm.$destroy();
  });

  describe('severity', () => {
    beforeEach(() => {
      vm = mountComponentWithStore(Component, { store });
    });

    it('should display all filters', () => {
      expect(vm.$el.querySelectorAll('.js-filter')).toHaveLength(3);
    });

    it('should display "Hide dismissed vulnerabilities" toggle', () => {
      expect(vm.$el.querySelectorAll('.js-toggle')).toHaveLength(1);
    });
  });

  describe('Report type', () => {
    const findReportTypeFilter = () => vm.$el.querySelector('.js-filter-report_type');

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
      vm = mountComponentWithStore(Component, {
        store,
        props: {
          securityReportSummary: {
            dast: dastProps,
          },
        },
      });
      expect(findReportTypeFilter().textContent).toContain(string);
    });
  });
});
