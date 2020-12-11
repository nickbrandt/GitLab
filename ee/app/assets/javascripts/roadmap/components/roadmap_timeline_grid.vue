<script>
import { totalDaysInQuarter, dayInQuarter, totalDaysInMonth } from '~/lib/utils/datetime_utility';

import {
  PRESET_TYPES,
  EPIC_DETAILS_CELL_WIDTH,
  TIMELINE_CELL_MIN_WIDTH,
  GRID_COLOR,
  CURRENT_DAY_INDICATOR_COLOR,
  DAYS_IN_WEEK,
} from '../constants';

export default {
  props: {
    presetType: {
      type: String,
      required: true,
    },
    timeframe: {
      type: Array,
      required: true,
    },
    height: {
      type: Number,
      required: true,
    },
  },
  data() {
    const currentDate = new Date();
    currentDate.setHours(0, 0, 0, 0);

    return {
      currentDate,
    };
  },
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
    /*
      Visual illustration of various computed properties.

      Diagram A:
                                              this.currentDate (today)
                                               Indicator here
                                                      *
                                                      |
          |   timeframe 0   |   timeframe 1   |   timeframe 2   | 
          <----------  this.offset  -------- -><----->|
                                                  ^
                                            this.innerOffset
  
      this.timeframeItemIndexForToday is 2
      this.timeframeItem is "timeframe 2"
    */
    timeframeItemIndexForToday() {
      return this.timeframe.findIndex(timeframeItem => {
        return this.hasToday(timeframeItem);
      });
    },
    timeframeItemForToday() {
      return this.timeframe[this.timeframeItemIndexForToday];
    },
    /*
      The next computed properties - innerOffset, offset, totalOffset -
        concern the position of the current indicator.
      Refer to Diagram A to get a visual sense for each value.
    */
    innerOffset() {
      let left;

      // Get total days of current timeframe Item and then
      // get size in % from current date and days in range
      // based on the current presetType
      if (this.presetTypeQuarters) {
        left =
          dayInQuarter(this.currentDate, this.timeframeItemForToday.range) /
          totalDaysInQuarter(this.timeframeItemForToday.range);
        left *= TIMELINE_CELL_MIN_WIDTH;
      } else if (this.presetTypeMonths) {
        left = this.currentDate.getDate() / totalDaysInMonth(this.timeframeItemForToday);
        left *= TIMELINE_CELL_MIN_WIDTH;
      } else if (this.presetTypeWeeks) {
        /*
          Explanation of the formula:

          Suppose the following cell represents a single weekly timeframe.
          (0 is sunday and 6 is saturday as usual.)

          <------    TIMELINE_CELL_MIN_WIDTH    ------>
          |.  0  .  1  .  2  .  3  .  4  .  5  .  6  .|
          <-----> This is how much width each day takes up: widthOfDay or TIMELINE_CELL_MIN_WIDTH/DAYS_IN_WEEK
          <-->    This is startingOffset or (TIMELINE_CELL_MIN_WIDTH/DAYS_IN_WEEK)/2.
          
          If we want to position the indicator at 2 (tuesday), we need the following offset value:
          startingOffset + widthOfDay * 2
            or
          <--> + <----> + <---->
        */
        const widthOfDay = TIMELINE_CELL_MIN_WIDTH / DAYS_IN_WEEK;
        const startingOffset = widthOfDay / 2;
        left = startingOffset + widthOfDay * this.currentDate.getDay();
      }

      return left;
    },
    offset() {
      return this.timeframeItemIndexForToday * TIMELINE_CELL_MIN_WIDTH;
    },
    totalOffset() {
      return this.innerOffset + this.offset;
    },
    rowWidth() {
      return this.timeframe.length * TIMELINE_CELL_MIN_WIDTH + EPIC_DETAILS_CELL_WIDTH;
    },
    canvasContext() {
      const { canvas } = this.$refs;
      return canvas.getContext('2d');
    },
  },
  watch: {
    height() {
      this.draw();
    },
    timeframe: {
      deep: true,
      handler() {
        this.draw();
      },
    },
  },
  mounted() {
    this.draw();
  },
  methods: {
    draw() {
      this.$nextTick(this.drawGrid);
      this.$nextTick(this.drawTimeIndicator);
    },
    drawGrid() {
      const ctx = this.canvasContext;
      ctx.beginPath();
      ctx.strokeStyle = GRID_COLOR;
      ctx.lineWidth = 1;
      this.timeframe
        .map((_, i) => i * TIMELINE_CELL_MIN_WIDTH)
        .forEach(x => {
          ctx.moveTo(x - 0.5, 0);
          ctx.lineTo(x - 0.5, this.height);
        });
      ctx.moveTo(0, this.height - 0.5);
      ctx.lineTo(this.rowWidth, this.height - 0.5);
      ctx.stroke();
    },
    drawTimeIndicator() {
      const ctx = this.canvasContext;
      ctx.beginPath();
      ctx.strokeStyle = CURRENT_DAY_INDICATOR_COLOR;
      ctx.lineWidth = 2;

      ctx.moveTo(this.totalOffset, 0);
      ctx.lineTo(this.totalOffset, this.height);
      ctx.stroke();
    },
    hasTodayForQuarterly(timeframeItem) {
      return (
        this.currentDate >= timeframeItem.range[0] && this.currentDate <= timeframeItem.range[2]
      );
    },
    hasTodayForMonthly(timeframeItem) {
      return (
        this.currentDate.getMonth() === timeframeItem.getMonth() &&
        this.currentDate.getFullYear() === timeframeItem.getFullYear()
      );
    },
    hasTodayForWeekly(timeframeItem) {
      const timeframeItemDate = new Date(timeframeItem.getTime());
      const headerSubItems = new Array(7)
        .fill()
        .map(
          (val, i) =>
            new Date(
              timeframeItemDate.getFullYear(),
              timeframeItemDate.getMonth(),
              timeframeItemDate.getDate() + i,
            ),
        );

      return (
        this.currentDate.getTime() >= headerSubItems[0].getTime() &&
        this.currentDate.getTime() <= headerSubItems[headerSubItems.length - 1].getTime()
      );
    },
    hasToday(timeframeItem) {
      if (this.presetTypeQuarters) {
        return this.hasTodayForQuarterly(timeframeItem);
      } else if (this.presetTypeMonths) {
        return this.hasTodayForMonthly(timeframeItem);
      }
      return this.hasTodayForWeekly(timeframeItem);
    },
  },
};
</script>

<template>
  <canvas
    ref="canvas"
    :height="`${height}px`"
    :width="`${rowWidth}px`"
    class="epic-timeline-canvas gl-absolute gl-top-0"
  ></canvas>
</template>
