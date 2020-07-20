import { shallowMount } from '@vue/test-utils';
import PolicyEditorApp from 'ee/threat_monitoring/components/policy_editor/app.vue';
import createStore from 'ee/threat_monitoring/store';

describe('PolicyEditorApp component', () => {
  let store;
  let wrapper;

  const factory = ({ propsData, state, options } = {}) => {
    store = createStore();
    Object.assign(store.state.threatMonitoring, {
      ...state,
    });

    wrapper = shallowMount(PolicyEditorApp, {
      propsData: {
        ...propsData,
      },
      store,
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders the header title', () => {
    factory({});
    expect(wrapper.find('header').exists()).toBe(true);
  });
});
