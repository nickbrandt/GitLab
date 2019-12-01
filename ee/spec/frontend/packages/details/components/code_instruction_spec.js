import { mount } from '@vue/test-utils';
import CodeInstruction from 'ee/packages/details/components/code_instruction.vue';

describe('Package code instruction', () => {
  let wrapper;

  const defaultProps = {
    instruction: 'npm i @my-package',
    copyText: 'Copy npm install command',
  };

  function createComponent(props = {}) {
    wrapper = mount(CodeInstruction, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('single line', () => {
    beforeEach(() => createComponent());

    it('to match the default snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('multiline', () => {
    beforeEach(() =>
      createComponent({
        instruction: 'this is some\nmultiline text',
        copyText: 'Copy the command',
        multiline: true,
      }),
    );

    it('to match the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
