import { shallowMount } from '@vue/test-utils';
import Pagination from 'ee/design_management/components/toolbar/pagination.vue';

describe('Design management pagination component', () => {
  let vm;

  function createComponent() {
    vm = shallowMount(Pagination, {
      propsData: {
        id: '2',
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    vm.destroy();
  });

  it('hides components when designs are empty', () => {
    expect(vm.element).toMatchSnapshot();
  });

  it('renders pagination buttons', () => {
    vm.setData({
      designs: [{ id: '1' }, { id: '2' }],
    });

    expect(vm.element).toMatchSnapshot();
  });
});
