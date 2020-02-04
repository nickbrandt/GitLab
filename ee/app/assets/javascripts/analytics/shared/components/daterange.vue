<script>
import { GlDaterangePicker, GlSprintf, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { getDayDifference } from '~/lib/utils/datetime_utility';
import { __, sprintf } from '~/locale';
import { OFFSET_DATE_BY_ONE } from '../constants';

export default {
  components: {
    GlDaterangePicker,
    GlSprintf,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    show: {
      type: Boolean,
      required: false,
      default: true,
    },
    startDate: {
      type: Date,
      required: false,
      default: null,
    },
    endDate: {
      type: Date,
      required: false,
      default: null,
    },
    minDate: {
      type: Date,
      required: false,
      default: null,
    },
    maxDate: {
      type: Date,
      required: false,
      default() {
        return new Date();
      },
    },
    maxDateRange: {
      type: Number,
      required: false,
      default: 0,
    },
    includeSelectedDate: {
      type: Boolean,
      required: false,
      default: false,
    },
    containerClasses: {
      type: String,
      required: false,
      // default: 'daterange-container d-flex flex-column flex-lg-row align-items-lg-center justify-content-lg-end',
      default: 'daterange-container d-flex flex-column flex-sm-row',
    },
    datepickerClasses: {
      type: String,
      required: false,
      // default: 'd-flex flex-column flex-lg-row',
      default: 'd-flex flex-column flex-sm-row',
    },
    startPickerClasses: {
      type: String,
      required: false,
      // default: 'd-flex flex-column flex-lg-row align-items-lg-center mr-lg-2 mb-2 mb-md-0',
      default: 'd-flex flex-column flex-sm-row',
    },
    endPickerClasses: {
      type: String,
      required: false,
      // default: 'd-flex flex-column flex-lg-row align-items-lg-center',
      default: 'd-flex flex-column flex-sm-row',
    },
  },
  data() {
    return {
      maxDateRangeTooltip: sprintf(__('Date range cannot exceed %{maxDateRange} days.'), {
        maxDateRange: this.maxDateRange,
      }),
    };
  },
  computed: {
    dateRange: {
      get() {
        return { startDate: this.startDate, endDate: this.endDate };
      },
      set({ startDate, endDate }) {
        this.$emit('change', { startDate, endDate });
      },
    },
    numberOfDays() {
      const dayDifference = getDayDifference(this.startDate, this.endDate);
      return this.includeSelectedDate ? dayDifference + OFFSET_DATE_BY_ONE : dayDifference;
    },
  },
};
</script>
<template>
  <div v-if="show" :class="containerClasses">
    <gl-daterange-picker
      v-model="dateRange"
      :class="datepickerClasses"
      :default-start-date="startDate"
      :default-end-date="endDate"
      :default-min-date="minDate"
      :max-date-range="maxDateRange"
      :default-max-date="maxDate"
      :same-day-selection="includeSelectedDate"
      theme="animate-picker"
      :start-picker-class="startPickerClasses"
      :end-picker-class="endPickerClasses"
    />
    <div v-if="maxDateRange" class="daterange-indicator">
      <!-- class="daterange-indicator d-flex flex-row flex-lg-row align-items-flex-start align-items-lg-center" -->
      <span class="number-of-days pl-2 pr-1">
        <gl-sprintf :message="n__('1 day', '%d days', numberOfDays)">
          <template #numberOfDays>{{ numberOfDays }}</template>
        </gl-sprintf>
      </span>
      <gl-icon
        v-gl-tooltip
        :title="maxDateRangeTooltip"
        name="question"
        :size="14"
        class="text-secondary"
      />
    </div>
  </div>
</template>
