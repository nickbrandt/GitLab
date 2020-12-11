<script>
import QuartersPresetMixin from '../mixins/quarters_preset_mixin';
import MonthsPresetMixin from '../mixins/months_preset_mixin';
import WeeksPresetMixin from '../mixins/weeks_preset_mixin';

import { s__, sprintf } from '~/locale';
import { dateInWords } from '~/lib/utils/datetime_utility';

import { PRESET_TYPES, TIMELINE_CELL_MIN_WIDTH } from '../constants';

export default {
  cellWidth: TIMELINE_CELL_MIN_WIDTH,
  props: {
    presetType: {
      type: String,
      required: true,
    },
    item: {
      type: Object,
      required: true,
    },
    timeframe: {
      type: Array,
      required: true,
    },
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
    /**
     * In case item's start date is out of range
     * we need to use original date instead of proxy date
     */
    startDate() {
      return this.item.startDateOutOfRange ? this.item.originalStartDate : this.item.startDate;
    },
    /**
     * In case item's end date is out of range
     * we need to use original date instead of proxy date
     */
    endDate() {
      return this.item.endDateOutOfRange ? this.item.originalEndDate : this.item.endDate;
    },
    startDateValues() {
      const { startDate } = this.item;

      return {
        day: startDate.getDay(),
        date: startDate.getDate(),
        month: startDate.getMonth(),
        year: startDate.getFullYear(),
        time: startDate.getTime(),
      };
    },
    endDateValues() {
      const { endDate } = this.item;

      return {
        day: endDate.getDay(),
        date: endDate.getDate(),
        month: endDate.getMonth(),
        year: endDate.getFullYear(),
        time: endDate.getTime(),
      };
    },
    timeframeItemIndex() {
      let hasStartDate = this.hasStartDateForMonth;
      if (this.presetTypeQuarters) {
        hasStartDate = this.hasStartDateForQuarter;
      } else if (this.presetTypeWeeks) {
        hasStartDate = this.hasStartDateForWeek;
      }

      return this.timeframe.findIndex(eachTimeframe => {
        return hasStartDate(eachTimeframe);
      });
    },
    /**
     * timeframeItem is the timeframe in which the timeline bar
     * representing item (epic or milestone) should be drawn.
     */
    timeframeItem() {
      return this.timeframe[this.timeframeItemIndex];
    },
    timeframeString() {
      if (this.item.startDateUndefined && this.item.endDateUndefined) {
        return sprintf(s__('GroupRoadmap|No start and end date'));
      } else if (this.item.startDateUndefined) {
        return sprintf(s__('GroupRoadmap|No start date – %{dateWord}'), {
          dateWord: dateInWords(this.endDate, true),
        });
      } else if (this.item.endDateUndefined) {
        return sprintf(s__('GroupRoadmap|%{dateWord} – No end date'), {
          dateWord: dateInWords(this.startDate, true),
        });
      }

      // In case both start and end date fall in same year
      // We should hide year from start date
      const startDateInWords = dateInWords(
        this.startDate,
        true,
        this.startDate.getFullYear() === this.endDate.getFullYear(),
      );

      const endDateInWords = dateInWords(this.endDate, true);
      return sprintf(s__('GroupRoadmap|%{startDateInWords} – %{endDateInWords}'), {
        startDateInWords,
        endDateInWords,
      });
    },
    /**
     * Visual illustration of various involved values involved in timelineBarStyle():
     *
     * Here, frame 2 corresponds to "timeframeItem" (or timeframeItemIndex is 2)
     *
     *                                                           <-   width  ->
     *                                                           |  timeline bar  |
     * |       frame 0       |       frame 1       |       frame 2     |      frame 3     |
     * <--         offsetForCurrentFrame        --><-- offset -->
     * <--                      left                          -->
     *
     */
    timelineBarStyle() {
      const offsetForCurrentFrame = TIMELINE_CELL_MIN_WIDTH * this.timeframeItemIndex;

      // offset can be NaN when the roadmap item (epic or milestone)
      //  does not have a fixed start date or out-of-range for the loaded timeframe.
      let offset = NaN;
      let width;

      if (this.presetTypeQuarters) {
        width = this.getTimelineBarWidthForQuarters(this.item);
        offset = this.getTimelineBarStartOffsetForQuarters(this.item, true);
        offset = this.convertOffsetToPixel(offset);
      } else if (this.presetTypeMonths) {
        width = this.getTimelineBarWidthForMonths();
        offset = this.getTimelineBarStartOffsetForMonths(this.item, true);
        offset = this.convertOffsetToPixel(offset);
      } else if (this.presetTypeWeeks) {
        width = this.getTimelineBarWidthForWeeks();
        offset = this.getTimelineBarStartOffsetForWeeks(this.item, true);
        // note: offset doesn't need to be converted to pixels for getTimelineBarStartOffsetForWeeks.
      }

      return {
        width: `${Math.round(width)}px`,
        left: Number.isNaN(offset) ? '' : `${offsetForCurrentFrame + offset}px`,
      };
    },
  },
  methods: {
    convertOffsetToPixel(x) {
      return Math.round(TIMELINE_CELL_MIN_WIDTH * (x / 100.0));
    },
    /**
     * timeframeHasToday is used to compute indicatorOffset property.
     */
    /*
      QuartersPresetMixin.methods contains:

      hasStartDateForQuarter(timeframeItem)
      isTimeframeUnderEndDateForQuarter(timeframeItem)
      getBarWidthForSingleQuarter(cellWidth, daysInQuarter, day)
      getTimelineBarStartOffsetForQuarters(item, returnRawNumber = false)
      getTimelineBarWidthForQuarters(item)
    */
    ...QuartersPresetMixin.methods,
    /*
      MonthsPresetMixin.methods contains:

      hasStartDateForMonth(timeframeItem)
      isTimeframeUnderEndDateForMonth(timeframeItem)
      getBarWidthForSingleMonth(cellWidth, daysInMonth, date)
      getTimelineBarStartOffsetForMonths(item, returnRawNumber = false)
      getTimelineBarWidthForMonths() 
    */
    ...MonthsPresetMixin.methods,
    /*
      WeeksPresetMixin.methods contains:

      hasStartDateForWeek(timeframeItem)
      getLastDayOfWeek(timeframeItem)
      isTimeframeUnderEndDateForWeek(timeframeItem)   
      getTimelineBarStartOffsetForWeeks(item, returnRawNumber = false) 
      getTimelineBarWidthForWeeks()
    */
    ...WeeksPresetMixin.methods,
  },
};
</script>

<template>
  <div>
    <slot name="item-details" :timeframe-string="timeframeString"> </slot>
    <slot> </slot>
    <slot
      name="timeline-bar"
      :timeframe-string="timeframeString"
      :timeline-bar-style="timelineBarStyle"
    >
    </slot>
  </div>
</template>
