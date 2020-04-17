import { shallowMount } from '@vue/test-utils';
import BurndownChart from 'ee/burndown_chart/components/burndown_chart.vue';

describe('burndown_chart', () => {
  let wrapper;

  const defaultProps = {
    startDate: '2019-08-07T00:00:00.000Z',
    dueDate: '2019-09-09T00:00:00.000Z',
    openIssuesCount: [],
    openIssuesWeight: [],
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(BurndownChart, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('with single point', () => {
    it('does not show guideline', () => {
      createComponent({
        openIssuesCount: [{ '2019-08-07T00:00:00.000Z': 100 }],
      });

      const data = wrapper.vm.dataSeries;
      expect(data.length).toBe(1);
      expect(data[0].name).not.toBe('Guideline');
    });
  });

  describe('with multiple points', () => {
    it('shows guideline', () => {
      createComponent({
        openIssuesCount: [
          { '2019-08-07T00:00:00.000Z': 100 },
          { '2019-08-08T00:00:00.000Z': 99 },
          { '2019-09-08T00:00:00.000Z': 1 },
        ],
      });

      const data = wrapper.vm.dataSeries;
      expect(data.length).toBe(2);
      expect(data[1].name).toBe('Guideline');
    });
  });
});
