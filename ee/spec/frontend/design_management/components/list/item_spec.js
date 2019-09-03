import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueRouter from 'vue-router';
import Item from 'ee/design_management/components/list/item.vue';

const localVue = createLocalVue();
localVue.use(VueRouter);
const router = new VueRouter();

describe('Design management list item component', () => {
  let wrapper;

  function createComponent(commentsCount = 1) {
    wrapper = shallowMount(Item, {
      sync: false,
      localVue,
      router,
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
    wrapper.destroy();
  });

  it('renders item with single comment', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders item with multiple comments', () => {
    createComponent(2);

    expect(wrapper.element).toMatchSnapshot();
  });

  it('hides comment count', () => {
    createComponent(0);

    expect(wrapper.element).toMatchSnapshot();
  });
});
