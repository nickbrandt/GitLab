import { shallowMount } from '@vue/test-utils';
import DesignIndex from 'ee/design_management/pages/design/index.vue';

describe('Design management design index page', () => {
  let vm;

  function createComponent(loading = false) {
    const $apollo = {
      queries: {
        design: {
          loading,
        },
      },
    };

    vm = shallowMount(DesignIndex, {
      propsData: { id: '1' },
      mocks: { $apollo },
    });
  }

  it('sets loading state', () => {
    createComponent(true);

    expect(vm.element).toMatchSnapshot();
  });

  it('renders design index', () => {
    createComponent();

    vm.setData({
      design: {
        filename: 'test.jpg',
        image: 'test.jpg',
        updatedAt: '01-01-2019',
        updatedBy: {
          name: 'test',
        },
      },
    });

    expect(vm.element).toMatchSnapshot();
  });
});
