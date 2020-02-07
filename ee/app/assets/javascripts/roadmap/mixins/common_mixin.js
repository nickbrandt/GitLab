import { totalDaysInMonth, dayInQuarter, totalDaysInQuarter } from '~/lib/utils/datetime_utility';

import { PRESET_TYPES, DAYS_IN_WEEK } from '../constants';

export default {
  computed: {
    presetTypeQuarters() {
      return this.presetType === PRESET_TYPES.QUARTERS;
    },
    presetTypeMonths() {
      return this.presetType === PRESET_TYPES.MONTHS;
    },
    presetTypeWeeks() {
      return this.presetType === PRESET_TYPES.WEEKS;
    },
    hasToday() {
      if (this.presetTypeQuarters) {
        return (
          this.currentDate >= this.timeframeItem.range[0] &&
          this.currentDate <= this.timeframeItem.range[2]
        );
      } else if (this.presetTypeMonths) {
        return (
          this.currentDate.getMonth() === this.timeframeItem.getMonth() &&
          this.currentDate.getFullYear() === this.timeframeItem.getFullYear()
        );
      }
      const timeframeItem = new Date(this.timeframeItem.getTime());
      const headerSubItems = new Array(7)
        .fill()
        .map(
          (val, i) =>
            new Date(
              timeframeItem.getFullYear(),
              timeframeItem.getMonth(),
              timeframeItem.getDate() + i,
            ),
        );

      return (
        this.currentDate.getTime() >= headerSubItems[0].getTime() &&
        this.currentDate.getTime() <= headerSubItems[headerSubItems.length - 1].getTime()
      );
    },
  },
  methods: {
    getIndicatorStyles() {
      let left;

      // Get total days of current timeframe Item and then
      // get size in % from current date and days in range
      // based on the current presetType
      if (this.presetTypeQuarters) {
        left = Math.floor(
          (dayInQuarter(this.currentDate, this.timeframeItem.range) /
            totalDaysInQuarter(this.timeframeItem.range)) *
            100,
        );
      } else if (this.presetTypeMonths) {
        left = Math.floor(
          (this.currentDate.getDate() / totalDaysInMonth(this.timeframeItem)) * 100,
        );
      } else if (this.presetTypeWeeks) {
        left = Math.floor(((this.currentDate.getDay() + 1) / DAYS_IN_WEEK) * 100 - DAYS_IN_WEEK);
      }

      return {
        left: `${left}%`,
      };
    },
  },
};
