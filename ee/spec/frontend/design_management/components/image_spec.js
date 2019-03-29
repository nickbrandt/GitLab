import { shallowMount } from '@vue/test-utils';
import DesignImage from 'ee/design_management/components/image.vue';

describe('Design management large image component', () => {
  let vm;

  function createComponent(propsData) {
    vm = shallowMount(DesignImage, {
      propsData,
    });
  }

  afterEach(() => {
    vm.destroy();
  });

  it('renders loading state', () => {
    createComponent({
      isLoading: true,
    });

    expect(vm.element).toMatchSnapshot();
  });

  it('renders image', () => {
    createComponent({
      isLoading: false,
      image: 'test.jpg',
      name: 'test',
    });

    expect(vm.element).toMatchSnapshot();
  });
});
