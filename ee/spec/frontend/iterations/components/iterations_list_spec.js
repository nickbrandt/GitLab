import IterationsList from 'ee/iterations/components/iterations_list.vue';
import { shallowMount } from '@vue/test-utils';
import timezoneMock from 'timezone-mock';

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
    timezoneMock.unregister();
  });

  it('shows empty state', () => {
    mountComponent();

    expect(wrapper.html()).toHaveText('No iterations to show');
  });

  describe('with iterations', () => {
    const iteration = {
      id: '123',
      title: 'Iteration #1',
      startDate: '2020-05-27',
      dueDate: '2020-06-04',
    };

    it('shows iteration', () => {
      mountComponent({
        iterations: [iteration],
      });

      expect(wrapper.html()).not.toHaveText('No iterations to show');
      expect(wrapper.html()).toHaveText(iteration.title);
    });

    it('displays dates in UTC time, regardless of user timezone', () => {
      timezoneMock.register('US/Pacific');

      mountComponent({
        iterations: [iteration],
      });

      expect(wrapper.html()).toHaveText('May 27, 2020');
      expect(wrapper.html()).toHaveText('Jun 4, 2020');
    });
  });
});
