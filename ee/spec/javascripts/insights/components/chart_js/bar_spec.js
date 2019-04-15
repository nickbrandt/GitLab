import Vue from 'vue';
import Chart from 'ee/insights/components/chart_js/bar.vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { chartInfo, chartData } from '../../mock_data';

describe('Insights bar chart component', () => {
  let vm;
  let mountComponent;
  const Component = Vue.extend(Chart);

  beforeEach(() => {
    mountComponent = data => {
      const props = data || {
        chartTitle: chartInfo.title,
        data: chartData,
      };
      return mountComponentWithStore(Component, { props });
    };

    vm = mountComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('has the correct config', done => {
    expect(vm.config.type).toBe('bar');
    expect(vm.config.data).toBe(chartData);
    expect(vm.config.options.title.text).toBe(chartInfo.title);

    done();
  });
});
