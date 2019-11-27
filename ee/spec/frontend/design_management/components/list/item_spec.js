import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueRouter from 'vue-router';
import Item from 'ee/design_management/components/list/item.vue';

const localVue = createLocalVue();
localVue.use(VueRouter);
const router = new VueRouter();

describe('Design management list item component', () => {
  let wrapper;

  function createComponent(notesCount = 1, event = 'NONE', isLoading = false) {
    wrapper = shallowMount(Item, {
      sync: false,
      localVue,
      router,
      propsData: {
        id: 1,
        filename: 'test',
        image: isLoading ? '' : 'http://via.placeholder.com/300',
        event,
        notesCount,
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

  it('renders item with correct status icon for modification event', () => {
    createComponent(0, 'MODIFICATION');

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders item with correct status icon for deletion event', () => {
    createComponent(0, 'DELETION');

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders item with correct status icon for creation event', () => {
    createComponent(0, 'CREATION');

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders item with no status icon for none event', () => {
    createComponent(0, 'NONE');

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders loading spinner when no image prop present', () => {
    createComponent(0, 'NONE', true);

    expect(wrapper.element).toMatchSnapshot();
  });
});
