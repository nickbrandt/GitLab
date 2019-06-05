import { createLocalVue, shallowMount } from '@vue/test-utils';
import DependencyListAlert from 'ee/dependencies/components/dependency_list_alert.vue';
import DependencyListIncompleteAlert from 'ee/dependencies/components/dependency_list_incomplete_alert.vue';

describe('DependencyListIncompleteAlert component', () => {
  let wrapper;

  const factory = (options = {}) => {
    const localVue = createLocalVue();

    wrapper = shallowMount(localVue.extend(DependencyListIncompleteAlert), {
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

  describe('when the generic alert component emits a close event', () => {
    let closeListenerSpy;

    beforeEach(() => {
      closeListenerSpy = jest.fn();

      factory({
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
