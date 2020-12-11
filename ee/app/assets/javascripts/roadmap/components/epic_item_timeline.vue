<script>
import { GlPopover, GlProgressBar, GlIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { generateKey } from '../utils/epic_utils';

import {
  EPIC_DETAILS_CELL_WIDTH,
  PERCENTAGE,
  SMALL_TIMELINE_BAR,
  TIMELINE_CELL_MIN_WIDTH,
} from '../constants';

export default {
  cellWidth: TIMELINE_CELL_MIN_WIDTH,
  components: {
    GlIcon,
    GlPopover,
    GlProgressBar,
  },
  props: {
    timeframeString: {
      type: String,
      required: true,
    },
    epic: {
      type: Object,
      required: true,
    },
    timelineBarStyle: {
      type: Object,
      required: true,
    },
    clientWidth: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    timelineBarInnerStyle() {
      return {
        left: `${EPIC_DETAILS_CELL_WIDTH}px`,
        maxWidth: `${this.clientWidth - EPIC_DETAILS_CELL_WIDTH}px`,
      };
    },
    isTimelineBarSmall() {
      const { width } = this.timelineBarStyle;
      return width < SMALL_TIMELINE_BAR;
    },
    timelineBarTitle() {
      return this.isTimelineBarSmall ? '...' : this.epic.title;
    },
    epicTotalWeight() {
      if (this.epic.descendantWeightSum) {
        const { openedIssues, closedIssues } = this.epic.descendantWeightSum;
        return openedIssues + closedIssues;
      }
      return undefined;
    },
    epicWeightPercentage() {
      return this.epicTotalWeight
        ? Math.round(
            (this.epic.descendantWeightSum.closedIssues / this.epicTotalWeight) * PERCENTAGE,
          )
        : 0;
    },
    epicWeightPercentageText() {
      return sprintf(__(`%{percentage}%% weight completed`), {
        percentage: this.epicWeightPercentage,
      });
    },
    popoverWeightText() {
      if (this.epic.descendantWeightSum) {
        return sprintf(__('%{completedWeight} of %{totalWeight} weight completed'), {
          completedWeight: this.epic.descendantWeightSum.closedIssues,
          totalWeight: this.epicTotalWeight,
        });
      }
      return __('- of - weight completed');
    },
  },
  methods: {
    generateKey,
  },
};
</script>

<template>
  <span
    class="gl-absolute gl-top-0 gl-bg-transparent gl-h-full"
    :style="{ width: `${this.$options.cellWidth}px` }"
    data-testid="epic-timeline-bar"
    data-qa-selector="epic_timeline_bar"
  >
    <a
      :id="generateKey(epic)"
      :href="epic.webUrl"
      :style="timelineBarStyle"
      class="epic-bar gl-absolute gl-z-index-3 gl-rounded-base"
      :class="{ 'epic-bar-child-epic': epic.isChildEpic }"
      data-testid="epic-bar"
    >
      <div class="epic-bar-inner gl-px-3 gl-py-2" :style="timelineBarInnerStyle">
        <p class="epic-bar-title gl-text-truncate gl-m-0">{{ timelineBarTitle }}</p>

        <div v-if="!isTimelineBarSmall" class="gl-display-flex gl-align-items-center">
          <gl-progress-bar
            class="epic-bar-progress gl-flex-grow-1 gl-mr-2"
            :value="epicWeightPercentage"
            aria-hidden="true"
          />
          <div class="gl-font-sm gl-display-flex gl-align-items-center gl-white-space-nowrap">
            <gl-icon class="gl-mr-1" :size="12" name="weight" />
            <p class="gl-m-0" :aria-label="epicWeightPercentageText">{{ epicWeightPercentage }}%</p>
          </div>
        </div>
      </div>
    </a>
    <gl-popover :target="generateKey(epic)" :title="epic.title" triggers="hover" placement="left">
      <p class="gl-text-gray-500 gl-m-0">{{ timeframeString }}</p>
      <p class="gl-m-0">{{ popoverWeightText }}</p>
    </gl-popover>
  </span>
</template>
