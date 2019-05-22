import { createLocalVue, shallowMount } from '@vue/test-utils';
import DependencyListIncompleteAlert from 'ee/dependencies/components/dependency_list_incomplete_alert.vue';

describe('DependencyListIncompleteAlert component', () => {
  let wrapper;

  const factory = () => {
    const localVue = createLocalVue();

    wrapper = shallowMount(localVue.extend(DependencyListIncompleteAlert), {
      localVue,
      sync: false,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('matches the snapshot', () => {
    factory();
    expect(wrapper.element).toMatchSnapshot();
  });
});
