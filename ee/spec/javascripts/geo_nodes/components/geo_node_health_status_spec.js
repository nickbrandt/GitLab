import Vue from 'vue';

import geoNodeHealthStatusComponent from 'ee/geo_nodes/components/geo_node_health_status.vue';
import { HEALTH_STATUS_ICON, HEALTH_STATUS_CLASS } from 'ee/geo_nodes/constants';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockNodeDetails } from '../mock_data';

const createComponent = (status = mockNodeDetails.health) => {
  const Component = Vue.extend(geoNodeHealthStatusComponent);

  return mountComponent(Component, {
    status,
  });
};

describe('GeoNodeHealthStatusComponent', () => {
  describe('computed', () => {
    describe('healthCssClass', () => {
      it('returns CSS class representing `status` prop value', () => {
        const vm = createComponent('healthy');

        expect(vm.healthCssClass).toBe(HEALTH_STATUS_CLASS.healthy);
        vm.$destroy();
      });
    });

    describe('statusIconName', () => {
      it('returns icon name representing `status` prop value', () => {
        let vm = createComponent('healthy');

        expect(vm.statusIconName).toBe(HEALTH_STATUS_ICON.healthy);
        vm.$destroy();

        vm = createComponent('unhealthy');

        expect(vm.statusIconName).toBe(HEALTH_STATUS_ICON.unhealthy);
        vm.$destroy();

        vm = createComponent('disabled');

        expect(vm.statusIconName).toBe(HEALTH_STATUS_ICON.disabled);
        vm.$destroy();

        vm = createComponent('unknown');

        expect(vm.statusIconName).toBe(HEALTH_STATUS_ICON.unknown);
        vm.$destroy();

        vm = createComponent('offline');

        expect(vm.statusIconName).toBe(HEALTH_STATUS_ICON.offline);
        vm.$destroy();
      });
    });
  });

  describe('template', () => {
    it('renders container elements correctly', () => {
      const vm = createComponent('Healthy');

      expect(vm.$el.classList.contains('detail-section-item')).toBe(true);
      expect(vm.$el.querySelector('.node-detail-title').innerText.trim()).toBe('Health status');

      const iconContainerEl = vm.$el.querySelector('.node-health-status');

      expect(iconContainerEl).not.toBeNull();
      expect(iconContainerEl.querySelector('svg use').getAttribute('xlink:href')).toContain(
        '#status_success',
      );

      expect(iconContainerEl.querySelector('.status-text').innerText.trim()).toBe('Healthy');
      vm.$destroy();
    });
  });
});
