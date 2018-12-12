import Vue from 'vue';
import component from 'ee/security_dashboard/components/filters.vue';
import createStore from 'ee/security_dashboard/store';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';

describe('Filter component', () => {
  let vm;
  const props = { dashboardDocumentation: '' };
  const store = createStore();
  const Component = Vue.extend(component);

  describe('severity', () => {
    beforeEach(() => {
      vm = mountComponentWithStore(Component, { store, props });
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('should display both filters', () => {
      expect(vm.$el.querySelectorAll('.js-filter').length).toEqual(2);
    });
  });
});
