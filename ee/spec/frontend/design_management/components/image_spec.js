import { shallowMount } from '@vue/test-utils';
import DesignImage from 'ee/design_management/components/image.vue';

describe('Design management large image component', () => {
  let wrapper;

  function createComponent(propsData) {
    wrapper = shallowMount(DesignImage, {
      propsData,
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders loading state', () => {
    createComponent({
      isLoading: true,
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders image', () => {
    createComponent({
      isLoading: false,
      image: 'test.jpg',
      name: 'test',
    });

    expect(wrapper.element).toMatchSnapshot();
  });
});
