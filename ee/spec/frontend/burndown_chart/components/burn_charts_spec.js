import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import BurnCharts from 'ee/burndown_chart/components/burn_charts.vue';
import BurndownChart from 'ee/burndown_chart/components/burndown_chart.vue';

describe('burndown_chart', () => {
  let wrapper;

  const findChartsTitle = () => wrapper.find({ ref: 'chartsTitle' });
  const findIssuesButton = () => wrapper.find({ ref: 'totalIssuesButton' });
  const findWeightButton = () => wrapper.find({ ref: 'totalWeightButton' });
  const findActiveButtons = () =>
    wrapper.findAll(GlButton).filter(button => button.attributes().category === 'primary');
  const findBurndownChart = () => wrapper.find(BurndownChart);

  const defaultProps = {
    startDate: '2019-08-07T00:00:00.000Z',
    dueDate: '2019-09-09T00:00:00.000Z',
    openIssuesCount: [],
    openIssuesWeight: [],
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(BurnCharts, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  let origProp;

  beforeEach(() => {
    origProp = window.gon;
    window.gon = {
      features: {
        burnupCharts: false,
      },
    };
  });

  afterEach(() => {
    window.gon = origProp;
  });

  it('includes Issues and Issue weight buttons', () => {
    createComponent();

    expect(findIssuesButton().text()).toBe('Issues');
    expect(findWeightButton().text()).toBe('Issue weight');
  });

  it('defaults to total issues', () => {
    createComponent();

    expect(findActiveButtons().length).toBe(1);
    expect(
      findActiveButtons()
        .at(0)
        .text(),
    ).toBe('Issues');
    expect(findBurndownChart().props().issuesSelected).toBe(true);
  });

  it('toggles Issue weight', () => {
    createComponent();

    findWeightButton().vm.$emit('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(findActiveButtons().length).toBe(1);
      expect(
        findActiveButtons()
          .at(0)
          .text(),
      ).toBe('Issue weight');
    });
  });

  describe('feature disabled', () => {
    beforeEach(() => {
      window.gon.features.burnupCharts = false;

      createComponent();
    });

    it('does not reduce width of burndown chart', () => {
      expect(findBurndownChart().classes()).toEqual([]);
    });

    it('sets section title and chart title correctly', () => {
      expect(findChartsTitle().text()).toBe('Burndown chart');
      expect(findBurndownChart().props().showTitle).toBe(false);
    });
  });

  describe('feature enabled', () => {
    beforeEach(() => {
      window.gon.features.burnupCharts = true;

      createComponent();
    });

    it('reduces width of burndown chart', () => {
      expect(findBurndownChart().classes()).toContain('col-md-6');
    });

    it('sets section title and chart title correctly', () => {
      expect(findChartsTitle().text()).toBe('Charts');
      expect(findBurndownChart().props().showTitle).toBe(true);
    });
  });
});
