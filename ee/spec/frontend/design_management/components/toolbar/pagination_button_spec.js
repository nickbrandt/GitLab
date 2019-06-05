import { shallowMount } from '@vue/test-utils';
import PaginationButton from 'ee/design_management/components/toolbar/pagination_button.vue';

describe('Design management pagination button component', () => {
  let vm;

  function createComponent(design = null) {
    vm = shallowMount(PaginationButton, {
      propsData: {
        design,
        title: 'Test title',
        iconName: 'angle-right',
      },
      stubs: ['router-link'],
    });
  }

  afterEach(() => {
    vm.destroy();
  });

  it('disables button when no design is passed', () => {
    createComponent();

    expect(vm.element).toMatchSnapshot();
  });

  it('renders router-link', () => {
    createComponent({ id: '2' });

    expect(vm.element).toMatchSnapshot();
  });

  describe('designLink', () => {
    it('returns empty link when design is null', () => {
      createComponent();

      expect(vm.vm.designLink).toEqual({});
    });

    it('returns design link', () => {
      createComponent({ id: '2', filename: 'test' });

      expect(vm.vm.designLink).toEqual({
        name: 'design',
        params: { id: 'test' },
      });
    });
  });
});
