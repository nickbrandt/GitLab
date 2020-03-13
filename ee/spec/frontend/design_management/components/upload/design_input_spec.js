import { mount } from '@vue/test-utils';
import DesignInput from 'ee/design_management/components/upload/design_input.vue';

describe('Design management upload button component', () => {
  let wrapper;

  function createComponent() {
    wrapper = mount(DesignInput);
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders design input', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });
});
