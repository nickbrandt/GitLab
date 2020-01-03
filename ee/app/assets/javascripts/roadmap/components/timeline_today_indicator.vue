<script>
import { totalDaysInMonth, dayInQuarter, totalDaysInQuarter } from '~/lib/utils/datetime_utility';

import { EPIC_DETAILS_CELL_WIDTH, PRESET_TYPES, DAYS_IN_WEEK, SCROLL_BAR_SIZE } from '../constants';

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
      todayBarStyles: {},
      todayBarReady: true,
    };
  },
  mounted() {
    eventHub.$on('epicsListScrolled', this.handleEpicsListScroll);
    this.$nextTick(() => {
      this.todayBarStyles = this.getTodayBarStyles();
    });
  },
  beforeDestroy() {
    eventHub.$off('epicsListScrolled', this.handleEpicsListScroll);
  },
  methods: {
    getTodayBarStyles() {
      let left;

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

      return {
        left: `${left}%`,
        height: `calc(100vh - ${this.$el.getBoundingClientRect().y + SCROLL_BAR_SIZE}px)`,
      };
    },
    handleEpicsListScroll() {
      const indicatorX = this.$el.getBoundingClientRect().x;
      const rootOffsetLeft = this.$root.$el.parentElement.offsetLeft;

      // 3px to compensate size of bubble on top of Indicator
      this.todayBarReady = indicatorX - rootOffsetLeft >= EPIC_DETAILS_CELL_WIDTH + 3;
    },
  },
};
</script>

<template>
  <span :class="{ invisible: !todayBarReady }" :style="todayBarStyles" class="today-bar"></span>
</template>
