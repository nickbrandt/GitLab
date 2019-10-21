import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueRouter from 'vue-router';
import Toolbar from 'ee/design_management/components/toolbar/index.vue';
import DeleteButton from 'ee/design_management/components/delete_button.vue';

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

  function createComponent(isLoading = false, createDesign = true, props) {
    const updatedAt = new Date();
    updatedAt.setHours(updatedAt.getHours() - 1);

    wrapper = shallowMount(Toolbar, {
      sync: false,
      localVue,
      router,
      propsData: {
        id: '1',
        isLatestVersion: true,
        isLoading,
        isDeleting: false,
        name: 'test.jpg',
        updatedAt: updatedAt.toString(),
        updatedBy: {
          name: 'Test Name',
        },
        ...props,
      },
      stubs: {
        'router-link': RouterLinkStub,
      },
    });

    wrapper.setData({
      permissions: {
        createDesign,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders design and updated data', () => {
    createComponent();

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.element).toMatchSnapshot();
    });
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

  it('renders delete button on latest designs version with logged in user', () => {
    createComponent();

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.find(DeleteButton).exists()).toBe(true);
    });
  });

  it('does not render delete button on non-latest version', () => {
    createComponent(false, true, { isLatestVersion: false });

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.find(DeleteButton).exists()).toBe(false);
    });
  });

  it('does not render delete button when user is not logged in', () => {
    createComponent(false, false);

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.find(DeleteButton).exists()).toBe(false);
    });
  });

  it('emits `delete` event on deleteButton `deleteSelectedDesigns` event', () => {
    createComponent();

    return wrapper.vm.$nextTick().then(() => {
      wrapper.find(DeleteButton).vm.$emit('deleteSelectedDesigns');
      expect(wrapper.emitted().delete).toBeTruthy();
    });
  });
});
