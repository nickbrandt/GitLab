import { shallowMount } from '@vue/test-utils';
import Toolbar from 'ee/design_management/components/toolbar/index.vue';

const RouterLinkStub = {
  props: {
    to: {
      type: Object,
    },
  },
  render(createElement) {
    return createElement('a', {}, this.$slots.default);
  },
};

describe('Design management toolbar component', () => {
  let vm;

  function createComponent(isLoading = false) {
    const updatedAt = new Date();
    updatedAt.setHours(updatedAt.getHours() - 1);

    vm = shallowMount(Toolbar, {
      propsData: {
        id: '1',
        isLoading,
        name: 'test.jpg',
        updatedAt: updatedAt.toString(),
        updatedBy: {
          name: 'Test Name',
        },
      },
      stubs: {
        'router-link': RouterLinkStub,
      },
    });
  }

  it('renders loading icon', () => {
    createComponent(true);

    expect(vm.element).toMatchSnapshot();
  });

  it('renders design and updated data', () => {
    createComponent();

    expect(vm.element).toMatchSnapshot();
  });

  it('links back to designs list', () => {
    createComponent();

    const link = vm.find('a');

    expect(link.props('to')).toEqual({
      name: 'designs',
    });
  });
});
