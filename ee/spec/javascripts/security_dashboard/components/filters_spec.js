import Vue from 'vue';
import component from 'ee/security_dashboard/components/filters.vue';
import createStore from 'ee/security_dashboard/store';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';

describe('Filter component', () => {
  let vm;
  const store = createStore();
  const Component = Vue.extend(component);

  describe('severity', () => {
    beforeEach(() => {
      vm = mountComponentWithStore(Component, { store });
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('should display all filters', () => {
      expect(vm.$el.querySelectorAll('.js-filter').length).toEqual(4);
    });

    it('should display "Hide dismissed vulnerabilities" toggle', () => {
      expect(vm.$el.querySelectorAll('.js-toggle').length).toEqual(1);
    });
  });
});
