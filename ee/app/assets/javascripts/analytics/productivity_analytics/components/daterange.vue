<script>
import { mapState, mapActions } from 'vuex';
import { GlDaterangePicker } from '@gitlab/ui';
import { getDateInPast } from '~/lib/utils/datetime_utility';
import { defaultDaysInPast } from '../constants';

export default {
  components: {
    GlDaterangePicker,
  },
  computed: {
    ...mapState('filters', ['groupNamespace', 'startDate', 'endDate']),
    dateRange: {
      get() {
        return { startDate: this.startDate, endDate: this.endDate };
      },
      set({ startDate, endDate }) {
        this.setDateRange({ startDate, endDate });
      },
    },
  },
  mounted() {
    this.initDateRange();
  },
  methods: {
    ...mapActions('filters', ['setDateRange']),
    initDateRange() {
      const endDate = new Date(Date.now());
      const startDate = new Date(getDateInPast(endDate, defaultDaysInPast));

      // let's not fetch data since we might not have a groupNamespace selected yet
      // this just populates the store with the initial data and waits for a groupNamespace to be set
      this.setDateRange({ skipFetch: true, startDate, endDate });
    },
  },
};
</script>
<template>
  <div
    v-if="groupNamespace"
    class="daterange-container d-flex flex-column flex-lg-row align-items-lg-center justify-content-lg-end"
  >
    <gl-daterange-picker
      v-model="dateRange"
      class="d-flex flex-column flex-lg-row"
      :default-start-date="startDate"
      :default-end-date="endDate"
      theme="animate-picker"
      start-picker-class="d-flex flex-column flex-lg-row align-items-lg-center mr-lg-2 mb-2 mb-md-0"
      end-picker-class="d-flex flex-column flex-lg-row align-items-lg-center"
    />
  </div>
</template>
