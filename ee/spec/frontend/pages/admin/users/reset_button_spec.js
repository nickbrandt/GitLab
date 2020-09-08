import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import ResetButton from 'ee/pages/admin/users/pipeline_minutes/reset_button.vue';
import axios from '~/lib/utils/axios_utils';

const defaultProps = { resetMinutesPath: '/adming/reset_minutes' };
const toastMock = {
  show: jest.fn(),
};

describe('Reset pipeline minutes button', () => {
  let wrapper;
  let mock;

  beforeEach(() => {
    wrapper = shallowMount(ResetButton, {
      provide: {
        ...defaultProps,
      },
      mocks: {
        $toast: toastMock,
      },
    });

    mock = new MockAdapter(axios);
    mock.onPost(defaultProps.resetMinutesPath).reply(200, {});
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
    wrapper = null;
  });

  const findResetButton = () => wrapper.find(GlButton);

  it('should contain a button with the "Reset pipeline minutes" text', () => {
    const button = findResetButton();

    expect(button.text()).toBe('Reset pipeline minutes');
  });

  it('should call do a network request when reseting the pipelines', () => {
    const axiosSpy = jest.spyOn(axios, 'post');

    wrapper.vm.resetPipelineMinutes();

    return wrapper.vm.$nextTick().then(() => {
      expect(axiosSpy).toHaveBeenCalled();
    });
  });
});
