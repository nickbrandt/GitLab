import { shallowMount } from '@vue/test-utils';
import Item from 'ee/design_management/components/list/item.vue';

describe('Design management list item component', () => {
  let vm;

  function createComponent(commentsCount = 1) {
    vm = shallowMount(Item, {
      propsData: {
        id: 1,
        name: 'test',
        image: 'http://via.placeholder.com/300',
        commentsCount,
        updatedAt: '01-01-2019',
      },
      stubs: ['router-link'],
    });
  }

  afterEach(() => {
    vm.destroy();
  });

  it('renders item with single comment', () => {
    createComponent();

    expect(vm.element).toMatchSnapshot();
  });

  it('renders item with multiple comments', () => {
    createComponent(2);

    expect(vm.element).toMatchSnapshot();
  });

  it('hides comment count', () => {
    createComponent(0);

    expect(vm.element).toMatchSnapshot();
  });
});
