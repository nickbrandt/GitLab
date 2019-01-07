import Vue from 'vue';
import component from 'ee/security_dashboard/components/filter.vue';
import createStore from 'ee/security_dashboard/store';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';

describe('Filter component', () => {
  let vm;
  let props;
  const store = createStore();
  const Component = Vue.extend(component);

  describe('severity', () => {
    beforeEach(() => {
      props = { filterId: 'severity', dashboardDocumentation: '' };
      vm = mountComponentWithStore(Component, { store, props });
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('should display all 9 severity options', () => {
      expect(vm.$el.querySelectorAll('.dropdown-item').length).toEqual(9);
    });

    it('should display a check next to only the selected item', () => {
      expect(vm.$el.querySelectorAll('.dropdown-item .js-check').length).toEqual(1);
    });

    it('should display "Severity" as the option name', () => {
      expect(vm.$el.querySelector('.js-name').textContent).toContain('Severity');
    });

    it('should not display the help popover', () => {
      expect(vm.$el.querySelector('.js-help')).toBeNull();
    });
  });

  describe('Report type', () => {
    beforeEach(() => {
      props = { filterId: 'report_type', dashboardDocumentation: '' };
      vm = mountComponentWithStore(Component, { store, props });
    });

    it('should display the help popover', () => {
      expect(vm.$el.querySelector('.js-help')).not.toBeNull();
    });
  });
});
