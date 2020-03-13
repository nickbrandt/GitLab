<script>
import { GlPopover, GlProgressBar } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';

import CommonMixin from '../mixins/common_mixin';
import QuartersPresetMixin from '../mixins/quarters_preset_mixin';
import MonthsPresetMixin from '../mixins/months_preset_mixin';
import WeeksPresetMixin from '../mixins/weeks_preset_mixin';

import CurrentDayIndicator from './current_day_indicator.vue';

import {
  EPIC_DETAILS_CELL_WIDTH,
  PERCENTAGE,
  PRESET_TYPES,
  SMALL_TIMELINE_BAR,
  TIMELINE_CELL_MIN_WIDTH,
  VERY_SMALL_TIMELINE_BAR,
} from '../constants';

export default {
  cellWidth: TIMELINE_CELL_MIN_WIDTH,
  components: {
    CurrentDayIndicator,
    Icon,
    GlPopover,
    GlProgressBar,
  },
  mixins: [CommonMixin, QuartersPresetMixin, MonthsPresetMixin, WeeksPresetMixin],
  props: {
    presetType: {
      type: String,
      required: true,
    },
    timeframe: {
      type: Array,
      required: true,
    },
    timeframeItem: {
      type: [Date, Object],
      required: true,
    },
    epic: {
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
    startDateValues() {
      const { startDate } = this.epic;

      return {
        day: startDate.getDay(),
        date: startDate.getDate(),
        month: startDate.getMonth(),
        year: startDate.getFullYear(),
        time: startDate.getTime(),
      };
    },
    endDateValues() {
      const { endDate } = this.epic;

      return {
        day: endDate.getDay(),
        date: endDate.getDate(),
        month: endDate.getMonth(),
        year: endDate.getFullYear(),
        time: endDate.getTime(),
      };
    },
    /**
     * In case Epic start date is out of range
     * we need to use original date instead of proxy date
     */
    startDate() {
      if (this.epic.startDateOutOfRange) {
        return this.epic.originalStartDate;
      }

      return this.epic.startDate;
    },
    /**
     * In case Epic end date is out of range
     * we need to use original date instead of proxy date
     */
    endDate() {
      if (this.epic.endDateOutOfRange) {
        return this.epic.originalEndDate;
      }
      return this.epic.endDate;
    },
    hasStartDate() {
      if (this.presetTypeQuarters) {
        return this.hasStartDateForQuarter();
      } else if (this.presetTypeMonths) {
        return this.hasStartDateForMonth();
      } else if (this.presetTypeWeeks) {
        return this.hasStartDateForWeek();
      }
      return false;
    },
    epicBarInnerStyle() {
      return {
        maxWidth: `${this.clientWidth - EPIC_DETAILS_CELL_WIDTH}px`,
      };
    },
    timelineBarWidth() {
      if (this.hasStartDate) {
        if (this.presetType === PRESET_TYPES.QUARTERS) {
          return this.getTimelineBarWidthForQuarters(this.epic);
        } else if (this.presetType === PRESET_TYPES.MONTHS) {
          return this.getTimelineBarWidthForMonths();
        } else if (this.presetType === PRESET_TYPES.WEEKS) {
          return this.getTimelineBarWidthForWeeks();
        }
      }
      return Infinity;
    },
    showTimelineBarEllipsis() {
      return this.timelineBarWidth < SMALL_TIMELINE_BAR;
    },
    timelineBarEllipsis() {
      if (this.timelineBarWidth < VERY_SMALL_TIMELINE_BAR) {
        return '.';
      } else if (this.timelineBarWidth < SMALL_TIMELINE_BAR) {
        return '...';
      }
      return '';
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
};
</script>

<template>
  <span class="epic-timeline-cell" data-qa-selector="epic_timeline_cell">
    <current-day-indicator :preset-type="presetType" :timeframe-item="timeframeItem" />
    <div class="epic-bar-wrapper">
      <a
        v-if="hasStartDate"
        :id="`epic-bar-${epic.id}`"
        :href="epic.webUrl"
        :style="timelineBarStyles(epic)"
        class="epic-bar"
      >
        <div class="epic-bar-inner" :style="epicBarInnerStyle">
          <gl-progress-bar
            class="epic-bar-progress append-bottom-2"
            :value="epicWeightPercentage"
          />

          <div v-if="showTimelineBarEllipsis" class="m-0">{{ timelineBarEllipsis }}</div>
          <div v-else class="d-flex">
            <span class="flex-grow-1 text-nowrap text-truncate mr-3">
              {{ epic.title }}
            </span>
            <span class="d-flex align-items-center text-nowrap">
              <icon class="append-right-2" :size="16" name="weight" />
              {{ epicWeightPercentage }}%
            </span>
          </div>
        </div>
      </a>
      <gl-popover
        :target="`epic-bar-${epic.id}`"
        :title="epic.description"
        triggers="hover focus"
        placement="right"
      >
        <p class="text-secondary m-0">{{ timeframeString(epic) }}</p>
        <p class="m-0">{{ popoverWeightText }}</p>
      </gl-popover>
    </div>
  </span>
</template>
