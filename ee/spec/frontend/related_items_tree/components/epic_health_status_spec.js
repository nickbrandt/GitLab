import { shallowMount } from '@vue/test-utils';
import { GlTooltip } from '@gitlab/ui';

import { mockEpic1 } from '../mock_data';

import EpicHealthStatus from 'ee/related_items_tree/components/epic_health_status.vue';

const createComponent = () => {
  const { healthStatus } = mockEpic1;

  return shallowMount(EpicHealthStatus, {
    propsData: {
      healthStatus,
    },
  });
};

describe('EpicHealthStatus', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders tooltip', () => {
    const tooltip = wrapper.find(GlTooltip);

    expect(tooltip).toExist();
  });

  it('renders with label with both short and long text', () => {
    const longLabels = wrapper.findAll('.health-label-long');
    const shortLabels = wrapper.findAll('.health-label-short');

    expect(longLabels.length).toBe(3);
    expect(shortLabels.length).toBe(3);

    const expectedLongLabels = ['issues on track', 'issues need attention', 'issues at risk'];

    expect(longLabels.length).toBe(expectedLongLabels.length);

    longLabels.wrappers.forEach((longLabelWrapper, index) => {
      expect(longLabelWrapper.text()).toEqual(expectedLongLabels[index]);
    });

    const expectedShortLabels = ['on track', 'need attention', 'at risk'];

    expect(shortLabels.length).toBe(expectedShortLabels.length);

    shortLabels.wrappers.forEach((shortLabelWrapper, index) => {
      expect(shortLabelWrapper.text()).toEqual(expectedShortLabels[index]);
    });
  });
});
