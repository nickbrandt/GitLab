import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueRouter from 'vue-router';
import Toolbar from 'ee/design_management/components/toolbar/index.vue';

const localVue = createLocalVue();
localVue.use(VueRouter);
const router = new VueRouter();

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
  let wrapper;

  function createComponent(isLoading = false) {
    const updatedAt = new Date();
    updatedAt.setHours(updatedAt.getHours() - 1);

    wrapper = shallowMount(Toolbar, {
      sync: false,
      localVue,
      router,
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

  it('renders design and updated data', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('links back to designs list', () => {
    createComponent();

    const link = wrapper.find('a');

    expect(link.props('to')).toEqual({
      name: 'designs',
      query: {
        version: undefined,
      },
    });
  });
});
