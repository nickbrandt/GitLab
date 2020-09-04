import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import ResetButton from 'ee/pages/admin/users/pipeline_minutes/reset_button.vue';

const defaultProps = { resetMinutesPath: '/adming/reset_minutes' };

describe('Reset pipeline minutes button', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(ResetButton, {
      provide: {
        ...defaultProps,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findResetButton = () => wrapper.find(GlButton);

  it('should contain a button with the "Reset pipeline minutes" text', () => {
    const button = findResetButton();

    expect(button.text()).toBe('Reset pipeline minutes');
  });

  it('should contain an href attribute set to the "resetMinutesPath" prop', () => {
    const button = findResetButton();

    expect(button.attributes('href')).toBe(defaultProps.resetMinutesPath);
  });
});
