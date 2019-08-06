import Vue from 'vue';
import requestWarning from '~/performance_bar/components/request_warning.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('request warning', () => {
  const htmlId = 'request-123';

  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('when the request has warnings', () => {
    beforeEach(() => {
      vm = mountComponent(Vue.extend(requestWarning), {
        htmlId,
        details: {
          warnings: ['gitaly calls: 30 over 10', 'gitaly duration: 1500 over 1000'],
        },
      });
    });

    it('adds a warning emoji with the correct ID', () => {
      const wrapper = vm.$el.querySelector('span[id]');

      expect(wrapper.id).toEqual(htmlId);
      expect(wrapper.querySelector('gl-emoji').dataset.name).toEqual('warning');
    });
  });

  describe('when the request does not have warnings', () => {
    beforeEach(() => {
      vm = mountComponent(Vue.extend(requestWarning), {
        htmlId,
        details: {
          warnings: [],
        },
      });
    });

    it('does nothing', () => {
      expect(vm.$el.innerText).toBeUndefined();
    });
  });
});
