import { shallowMount } from '@vue/test-utils';
import Index from 'ee/design_management/pages/index.vue';

describe('Design management index page', () => {
  let vm;

  function createComponent(loading = false) {
    const $apollo = {
      queries: {
        designs: {
          loading,
        },
      },
    };

    vm = shallowMount(Index, {
      mocks: { $apollo },
    });
  }

  describe('designs', () => {
    it('renders loading icon', () => {
      createComponent(true);

      expect(vm.element).toMatchSnapshot();
    });

    it('renders error', () => {
      createComponent();

      vm.setData({ error: true });

      expect(vm.element).toMatchSnapshot();
    });

    it('renders empty text', () => {
      createComponent();

      expect(vm.element).toMatchSnapshot();
    });

    it('renders designs list', () => {
      createComponent();

      vm.setData({ designs: ['design'] });

      expect(vm.element).toMatchSnapshot();
    });
  });
});
