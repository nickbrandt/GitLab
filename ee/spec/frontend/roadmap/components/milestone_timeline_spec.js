import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';

import milestoneTimelineComponent from 'ee/roadmap/components/milestone_timeline.vue';
import MilestoneItem from 'ee/roadmap/components/milestone_item.vue';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';

import { PRESET_TYPES } from 'ee/roadmap/constants';

import { mockTimeframeInitialDate, mockMilestone2, mockGroupId } from 'ee_jest/roadmap/mock_data';

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);

const createComponent = ({
  presetType = PRESET_TYPES.MONTHS,
  timeframe = mockTimeframeMonths,
  milestones = [mockMilestone2],
  currentGroupId = mockGroupId,
} = {}) => {
  const Component = Vue.extend(milestoneTimelineComponent);

  return shallowMount(Component, {
    propsData: {
      presetType,
      timeframe,
      milestones,
      currentGroupId,
    },
  });
};

describe('MilestoneTimelineComponent', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    it('renders component container element with class `milestone-timeline-cell`', () => {
      wrapper = createComponent();

      expect(wrapper.find('.milestone-timeline-cell').exists()).toBe(true);
    });

    it('renders MilestoneItem component', () => {
      wrapper = createComponent();

      expect(wrapper.find(MilestoneItem).exists()).toBe(true);
    });
  });
});
