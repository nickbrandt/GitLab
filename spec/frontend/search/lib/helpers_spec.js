import { createLocalVue, shallowMount } from '@vue/test-utils';
import { VueMountComponent } from '~/search/lib/helpers';

const localVue = createLocalVue();
localVue.use(VueMountComponent);

describe('Global Search Helpers', () => {
  let wrapper;

  const defaultComponent = {
    template: `<section></section>`,
  };

  const createComponent = (component = defaultComponent) => {
    wrapper = shallowMount(component, {
      localVue,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('VueMountComponent', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should provide $mountComponent to vue instance', () => {
      expect(wrapper.vm.$mountComponent).toExist();
    });
  });
});
