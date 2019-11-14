import { mount } from '@vue/test-utils';
import CodeInstruction from 'ee/packages/components/code_instruction.vue';

describe('Package code instruction', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(CodeInstruction, {
      propsData: {
        instruction: 'npm i @my-package',
        copyText: 'Copy npm install command',
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('to match the default snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});
