import IterationsList from 'ee/iterations/components/iterations_list.vue';
import { shallowMount } from '@vue/test-utils';

describe('Iterations list', () => {
  let wrapper;

  const mountComponent = (propsData = { iterations: [] }) => {
    wrapper = shallowMount(IterationsList, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('shows empty state', () => {
    mountComponent();

    expect(wrapper.html()).toHaveText('No iterations to show');
  });

  it('shows iteration', () => {
    const iteration = {
      id: '123',
      title: 'Iteration #1',
      startDate: '2020-05-27',
      dueDate: '2020-05-28',
    };

    mountComponent({
      iterations: [iteration],
    });

    expect(wrapper.html()).not.toHaveText('No iterations to show');
    expect(wrapper.html()).toHaveText(iteration.title);
  });
});
