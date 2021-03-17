import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import CopyableField from '~/vue_shared/components/sidebar/copyable_field.vue';

describe('SidebarCopyableField', () => {
  let wrapper;

  const defaultProps = {
    value: 'Gl-1',
    name: 'Reference',
  };

  const createComponent = (propsData = defaultProps) => {
    wrapper = shallowMount(CopyableField, {
      propsData,
      slots: {
        default: 'Reference: Gl-1',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  describe('template', () => {
    describe('when `isLoading` prop is `false`', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders copyable field', () => {
        expect(wrapper.text()).toContain('Reference: Gl-1');
      });

      it('renders ClipboardButton with correct props', () => {
        const clipboardButton = findClipboardButton();

        expect(clipboardButton.exists()).toBe(true);
        expect(clipboardButton.props('title')).toBe(`Copy ${defaultProps.name}`);
        expect(clipboardButton.props('text')).toBe(defaultProps.value);
      });

      it('does not render loading icon', () => {
        expect(findLoadingIcon().exists()).toBe(false);
      });
    });

    describe('when `isLoading` prop is `true`', () => {
      it('renders loading icon', () => {
        createComponent({ ...defaultProps, isLoading: true });

        expect(findLoadingIcon().exists()).toBe(true);
        expect(findLoadingIcon().props('label')).toBe('Loading Reference');
      });
    });
  });
});
