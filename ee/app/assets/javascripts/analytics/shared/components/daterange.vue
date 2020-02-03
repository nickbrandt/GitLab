<script>
import { GlDaterangePicker, GlSprintf, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { getDayDifference } from '~/lib/utils/datetime_utility';
import { __, sprintf } from '~/locale';

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
      rerquired: false,
      default: null,
    },
    maxDateRange: {
      type: Number,
      required: false,
      default: 0,
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
      return getDayDifference(this.startDate, this.endDate);
    },
  },
};
</script>
<template>
  <div
    v-if="show"
    class="daterange-container d-flex flex-column flex-lg-row align-items-lg-center justify-content-lg-end"
  >
    <gl-daterange-picker
      v-model="dateRange"
      class="d-flex flex-column flex-lg-row"
      :default-start-date="startDate"
      :default-end-date="endDate"
      :default-min-date="minDate"
      :max-date-range="maxDateRange"
      theme="animate-picker"
      start-picker-class="d-flex flex-column flex-lg-row align-items-lg-center mr-lg-2 mb-2 mb-md-0"
      end-picker-class="d-flex flex-column flex-lg-row align-items-lg-center"
    />
    <div
      v-if="maxDateRange"
      class="daterange-indicator d-flex flex-row flex-lg-row align-items-flex-start align-items-lg-center"
    >
      <span class="number-of-days pl-2 pr-1">
        <gl-sprintf :message="__('%{numberOfDays} days')">
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
