import { createLocalVue, shallowMount } from '@vue/test-utils';
import DependencyListJobFailedAlert from 'ee/dependencies/components/dependency_list_job_failed_alert.vue';

describe('DependencyListJobFailedAlert component', () => {
  let wrapper;

  const factory = (props = {}) => {
    const localVue = createLocalVue();

    wrapper = shallowMount(localVue.extend(DependencyListJobFailedAlert), {
      localVue,
      sync: false,
      propsData: { ...props },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('matches the snapshot', () => {
    factory({ jobPath: '/jobs/foo/3210' });
    expect(wrapper.element).toMatchSnapshot();
  });
});
