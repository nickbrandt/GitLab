import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon, GlIcon, GlButton } from '@gitlab/ui';
import SidebarTodos from '~/sidebar/components/todo_toggle/todo.vue';
import TodoButton from '~/vue_shared/components/todo_button.vue';

const defaultProps = {
  issuableId: 1,
  issuableType: 'epic',
};

describe('SidebarTodo', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(SidebarTodos, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        TodoButton,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when sidebar collapsed', () => {
    beforeEach(() => {
      createComponent({ collapsed: true });
    });

    it('renders button', () => {
      expect(wrapper.find('button').exists()).toBe(true);
    });

    it('renders correct default button icon', () => {
      expect(wrapper.find(GlIcon).props('name')).toBe('todo-done');
    });

    it('emits `toggleTodo` event when button clicked', () => {
      wrapper.find('button').trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted().toggleTodo).toBeTruthy();
      });
    });

    describe('when `isActionActive` prop is true', () => {
      beforeEach(() => {
        wrapper.setProps({ isActionActive: true });
        return wrapper.vm.$nextTick();
      });

      it('renders loading icon ', () => {
        expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
      });

      it('hides button icon', () => {
        expect(wrapper.find(GlIcon).isVisible()).toBe(false);
      });
    });

    it.each`
      isTodo   | iconClass        | label             | icon
      ${false} | ${''}            | ${'Add a To-Do'}  | ${'todo-add'}
      ${true}  | ${'todo-undone'} | ${'Mark as done'} | ${'todo-done'}
    `(
      'renders correct button when `isTodo` prop is `$isTodo`',
      async ({ isTodo, iconClass, label, icon }) => {
        wrapper.setProps({ isTodo });
        await wrapper.vm.$nextTick();

        const button = wrapper.find('button');
        const iconComponent = wrapper.find(GlIcon);

        expect(button.attributes('aria-label')).toBe(label);
        expect(iconComponent.classes().join(' ')).toBe(iconClass);
        expect(iconComponent.props('name')).toBe(icon);
      },
    );
  });

  describe('when sidebar not collapsed', () => {
    beforeEach(() => {
      createComponent({ collapsed: false });
    });

    it('renders GlButton', () => {
      expect(wrapper.find(GlButton).exists()).toBe(true);
    });

    it('renders correct default button label text', () => {
      expect(wrapper.find(GlButton).text()).toBe('Mark as done');
    });
  });
});
