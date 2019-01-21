<script>
import tooltip from '~/vue_shared/directives/tooltip';

import QuartersPresetMixin from '../mixins/quarters_preset_mixin';
import MonthsPresetMixin from '../mixins/months_preset_mixin';
import WeeksPresetMixin from '../mixins/weeks_preset_mixin';

import eventHub from '../event_hub';

import { EPIC_DETAILS_CELL_WIDTH, TIMELINE_CELL_MIN_WIDTH, PRESET_TYPES } from '../constants';

export default {
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
    shellWidth: {
      type: Number,
      required: true,
    },
    itemWidth: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      timelineBarReady: false,
      timelineBarStyles: '',
    };
  },
  computed: {
    itemStyles() {
      return {
        width: `${this.itemWidth}px`,
      };
    },
    showTimelineBar() {
      return this.hasStartDate();
    },
  },
  watch: {
    shellWidth: function shellWidth() {
      // Render timeline bar only when shellWidth is updated.
      this.renderTimelineBar();
    },
  },
  mounted() {
    eventHub.$on('refreshTimeline', this.renderTimelineBar);
  },
  beforeDestroy() {
    eventHub.$off('refreshTimeline', this.renderTimelineBar);
  },
  methods: {
    /**
     * Gets cell width based on total number months for
     * current timeframe and shellWidth excluding details cell width.
     *
     * In case cell width is too narrow, we have fixed minimum
     * cell width (TIMELINE_CELL_MIN_WIDTH) to obey.
     */
    getCellWidth() {
      const minWidth = (this.shellWidth - EPIC_DETAILS_CELL_WIDTH) / this.timeframe.length;

      return Math.max(minWidth, TIMELINE_CELL_MIN_WIDTH);
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
    /**
     * Renders timeline bar only if current
     * timeframe item has startDate for the epic.
     */
    renderTimelineBar() {
      if (this.hasStartDate()) {
        if (this.presetType === PRESET_TYPES.QUARTERS) {
          this.timelineBarStyles = `width: ${this.getTimelineBarWidthForQuarters()}px; ${this.getTimelineBarStartOffsetForQuarters()}`;
        } else if (this.presetType === PRESET_TYPES.MONTHS) {
          this.timelineBarStyles = `width: ${this.getTimelineBarWidthForMonths()}px; ${this.getTimelineBarStartOffsetForMonths()}`;
        } else if (this.presetType === PRESET_TYPES.WEEKS) {
          this.timelineBarStyles = `width: ${this.getTimelineBarWidthForWeeks()}px; ${this.getTimelineBarStartOffsetForWeeks()}`;
        }
        this.timelineBarReady = true;
      }
    },
  },
};
</script>

<template>
  <span :style="itemStyles" class="epic-timeline-cell">
    <div class="timeline-bar-wrapper">
      <a
        v-if="showTimelineBar"
        :href="epic.webUrl"
        :class="{
          'start-date-undefined': epic.startDateUndefined,
          'end-date-undefined': epic.endDateUndefined,
        }"
        :style="timelineBarStyles"
        class="timeline-bar"
      >
      </a>
    </div>
  </span>
</template>
