<script>
import { GlDaterangePicker } from '@gitlab/ui';

export default {
  components: {
    GlDaterangePicker,
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
      theme="animate-picker"
      start-picker-class="d-flex flex-column flex-lg-row align-items-lg-center mr-lg-2 mb-2 mb-md-0"
      end-picker-class="d-flex flex-column flex-lg-row align-items-lg-center"
    />
  </div>
</template>
