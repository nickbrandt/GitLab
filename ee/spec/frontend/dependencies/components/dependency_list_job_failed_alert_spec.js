import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import DependencyListAlert from 'ee/dependencies/components/dependency_list_alert.vue';
import DependencyListJobFailedAlert from 'ee/dependencies/components/dependency_list_job_failed_alert.vue';

describe('DependencyListJobFailedAlert component', () => {
  let wrapper;

  const factory = (options = {}) => {
    const localVue = createLocalVue();

    wrapper = shallowMount(localVue.extend(DependencyListJobFailedAlert), {
      localVue,
      sync: false,
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('matches the snapshot', () => {
    factory({ propsData: { jobPath: '/jobs/foo/3210' } });
    expect(wrapper.element).toMatchSnapshot();
  });

  it('inludes a button button if "jobPath" is given', () => {
    factory({ propsData: { jobPath: '/jobs/foo/3210' } });

    expect(wrapper.find(GlButton).exists()).toBe(true);
  });

  it('does not include a button if "jobPath" is not given', () => {
    factory();

    expect(wrapper.find(GlButton).exists()).toBe(false);
  });

  it.each([undefined, null, ''])(
    'does not include a button if "jobPath" is given but empty',
    jobPath => {
      factory({ propsData: { jobPath } });

      expect(wrapper.find(GlButton).exists()).toBe(false);
    },
  );

  describe('when the generic alert component emits a close event', () => {
    let closeListenerSpy;

    beforeEach(() => {
      closeListenerSpy = jest.fn();

      factory({
        propsData: { jobPath: '/jobs/foo/3210' },
        listeners: {
          close: closeListenerSpy,
        },
      });

      wrapper.find(DependencyListAlert).vm.$emit('close');
    });

    it('calls the given listener', () => {
      expect(closeListenerSpy).toHaveBeenCalledTimes(1);
    });
  });
});
