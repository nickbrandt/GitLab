import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import DependencyListIncompleteAlert from 'ee/dependencies/components/dependency_list_incomplete_alert.vue';

describe('DependencyListIncompleteAlert component', () => {
  let wrapper;

  const factory = (options = {}) => {
    const localVue = createLocalVue();

    wrapper = shallowMount(DependencyListIncompleteAlert, {
      localVue,
      sync: false,
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('matches the snapshot', () => {
    factory();
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('when the GlAlert component emits a dismiss event', () => {
    let dismissListenerSpy;

    beforeEach(() => {
      dismissListenerSpy = jest.fn();

      factory({
        listeners: {
          dismiss: dismissListenerSpy,
        },
      });

      wrapper.find(GlAlert).vm.$emit('dismiss');
    });

    it('calls the given listener', () => {
      expect(dismissListenerSpy).toHaveBeenCalledTimes(1);
    });
  });
});
