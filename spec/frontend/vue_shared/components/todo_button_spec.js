import { mount } from '@vue/test-utils';
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import TodoButton from '~/vue_shared/components/todo_button.vue';

const defaultProps = {
  issuableId: 1,
  issuableType: 'epic',
};

describe('Todo Button', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(TodoButton, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders GlButton', () => {
    createComponent();

    expect(wrapper.find(GlButton).exists()).toBe(true);
  });

  it('emits toggleTodo event when clicked', () => {
    createComponent();
    wrapper.find(GlButton).trigger('click');

    expect(wrapper.emitted().toggleTodo).toBeTruthy();
    expect(wrapper.emitted().toggleTodo[0]).toEqual([defaultProps]);
  });

  it.each`
    label             | isTodo
    ${'Mark as done'} | ${true}
    ${'Add a To-Do'}  | ${false}
  `('sets correct label when isTodo is $isTodo', ({ label, isTodo }) => {
    createComponent({ isTodo });

    expect(wrapper.find(GlButton).text()).toBe(label);
  });

  it('renders loading icon when `isActionActive` is true', () => {
    createComponent({ isActionActive: true });

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });
});
