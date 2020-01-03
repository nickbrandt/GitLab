<script>
import tooltip from '~/vue_shared/directives/tooltip';

import QuartersPresetMixin from '../mixins/quarters_preset_mixin';
import MonthsPresetMixin from '../mixins/months_preset_mixin';
import WeeksPresetMixin from '../mixins/weeks_preset_mixin';

import { TIMELINE_CELL_MIN_WIDTH, PRESET_TYPES } from '../constants';

export default {
  cellWidth: TIMELINE_CELL_MIN_WIDTH,
  directives: {
    tooltip,
  },
  mixins: [QuartersPresetMixin, MonthsPresetMixin, WeeksPresetMixin],
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
  },
  computed: {
    epicStartDateValues() {
      const { startDate } = this.epic;

      return {
        day: startDate.getDay(),
        date: startDate.getDate(),
        month: startDate.getMonth(),
        year: startDate.getFullYear(),
        time: startDate.getTime(),
      };
    },
    epicEndDateValues() {
      const { endDate } = this.epic;

      return {
        day: endDate.getDay(),
        date: endDate.getDate(),
        month: endDate.getMonth(),
        year: endDate.getFullYear(),
        time: endDate.getTime(),
      };
    },
    hasStartDate() {
      if (this.presetType === PRESET_TYPES.QUARTERS) {
        return this.hasStartDateForQuarter();
      } else if (this.presetType === PRESET_TYPES.MONTHS) {
        return this.hasStartDateForMonth();
      } else if (this.presetType === PRESET_TYPES.WEEKS) {
        return this.hasStartDateForWeek();
      }
      return false;
    },
    timelineBarStyles() {
      let barStyles = {};

      if (this.hasStartDate) {
        if (this.presetType === PRESET_TYPES.QUARTERS) {
          // CSS properties are a false positive: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/24
          // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
          barStyles = `width: ${this.getTimelineBarWidthForQuarters()}px; ${this.getTimelineBarStartOffsetForQuarters()}`;
        } else if (this.presetType === PRESET_TYPES.MONTHS) {
          // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
          barStyles = `width: ${this.getTimelineBarWidthForMonths()}px; ${this.getTimelineBarStartOffsetForMonths()}`;
        } else if (this.presetType === PRESET_TYPES.WEEKS) {
          // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
          barStyles = `width: ${this.getTimelineBarWidthForWeeks()}px; ${this.getTimelineBarStartOffsetForWeeks()}`;
        }
      }
      return barStyles;
    },
  },
};
</script>

<template>
  <span class="epic-timeline-cell" data-qa-selector="epic_timeline_cell">
    <div class="timeline-bar-wrapper">
      <a
        v-if="hasStartDate"
        :href="epic.webUrl"
        :class="{
          'start-date-undefined': epic.startDateUndefined,
          'end-date-undefined': epic.endDateUndefined,
        }"
        :style="timelineBarStyles"
        class="timeline-bar"
      ></a>
    </div>
  </span>
</template>
