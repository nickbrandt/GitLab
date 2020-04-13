import { shallowMount } from '@vue/test-utils';
import BurnCharts from 'ee/burndown_chart/components/burn_charts.vue';

describe('burndown_chart', () => {
  let wrapper;

  const issuesButton = () => wrapper.find({ ref: 'totalIssuesButton' });
  const weightButton = () => wrapper.find({ ref: 'totalWeightButton' });

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
        monacoSnippets: false,
      },
    };
  });

  afterEach(() => {
    window.gon = origProp;
  });

  it('inclues Issues and Issue weight buttons', () => {
    createComponent();

    expect(issuesButton().text()).toBe('Issues');
    expect(weightButton().text()).toBe('Issue weight');
  });

  it('defaults to total issues', () => {
    createComponent();

    expect(issuesButton().attributes('variant')).toBe('primary');
    expect(weightButton().attributes('variant')).toBe('inverted-primary');
  });

  it('toggles Issue weight', () => {
    createComponent();

    weightButton().vm.$emit('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(issuesButton().attributes('variant')).toBe('inverted-primary');
      expect(weightButton().attributes('variant')).toBe('primary');
    });
  });
});
