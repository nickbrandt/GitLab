<script>
import { totalDaysInMonth, dayInQuarter, totalDaysInQuarter } from '~/lib/utils/datetime_utility';

import { EPIC_DETAILS_CELL_WIDTH, PRESET_TYPES, DAYS_IN_WEEK } from '../constants';

import eventHub from '../event_hub';

export default {
  props: {
    presetType: {
      type: String,
      required: true,
    },
    currentDate: {
      type: Date,
      required: true,
    },
    timeframeItem: {
      type: [Date, Object],
      required: true,
    },
  },
  data() {
    return {
      todayBarStyles: '',
      todayBarReady: false,
    };
  },
  mounted() {
    eventHub.$on('epicsListRendered', this.handleEpicsListRender);
    eventHub.$on('epicsListScrolled', this.handleEpicsListScroll);
    eventHub.$on('refreshTimeline', this.handleEpicsListRender);
  },
  beforeDestroy() {
    eventHub.$off('epicsListRendered', this.handleEpicsListRender);
    eventHub.$off('epicsListScrolled', this.handleEpicsListScroll);
    eventHub.$off('refreshTimeline', this.handleEpicsListRender);
  },
  methods: {
    /**
     * This method takes height of current shell
     * and renders vertical line over the area where
     * today falls in current timeline
     */
    handleEpicsListRender({ todayBarReady }) {
      let left = 0;
      let height = 0;

      // Get total days of current timeframe Item and then
      // get size in % from current date and days in range
      // based on the current presetType
      if (this.presetType === PRESET_TYPES.QUARTERS) {
        left = Math.floor(
          (dayInQuarter(this.currentDate, this.timeframeItem.range) /
            totalDaysInQuarter(this.timeframeItem.range)) *
            100,
        );
      } else if (this.presetType === PRESET_TYPES.MONTHS) {
        left = Math.floor(
          (this.currentDate.getDate() / totalDaysInMonth(this.timeframeItem)) * 100,
        );
      } else if (this.presetType === PRESET_TYPES.WEEKS) {
        left = Math.floor(((this.currentDate.getDay() + 1) / DAYS_IN_WEEK) * 100 - DAYS_IN_WEEK);
      }

      // On initial load, container element height is 0
      if (this.$root.$el.clientHeight === 0) {
        height = window.innerHeight - this.$root.$el.offsetTop;
      } else {
        // When list is scrollable both vertically and horizontally
        // We set height using top-level parent container height & position of
        // today indicator element container.
        height = this.$root.$el.clientHeight - this.$el.parentElement.offsetTop;
      }

      this.todayBarStyles = {
        height: `${height}px`,
        left: `${left}%`,
      };
      this.todayBarReady = todayBarReady === undefined ? true : todayBarReady;
    },
    handleEpicsListScroll() {
      const indicatorX = this.$el.getBoundingClientRect().x;
      const rootOffsetLeft = this.$root.$el.offsetLeft;

      // 3px to compensate size of bubble on top of Indicator
      this.todayBarReady = indicatorX - rootOffsetLeft >= EPIC_DETAILS_CELL_WIDTH + 3;
    },
  },
};
</script>

<template>
  <span :class="{ invisible: !todayBarReady }" :style="todayBarStyles" class="today-bar"> </span>
</template>
