<script>
import { mapState, mapActions } from 'vuex';
import Dashboard from '../components/dashboard.vue';
import { timeRangeToQuery } from '../utils';
import { timeRangeFromParams } from '~/lib/utils/datetime_range';
import { defaultTimeRange } from '~/vue_shared/constants';

export default {
  components: {
    Dashboard,
  },
  props: {
    dashboardProps: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState('monitoringDashboard', ['timeRange']),
  },
  watch: {
    timeRange(timeRange) {
      // Update URL bar with time range parameters when time range changes
      this.$router.push({
        ...this.$route,
        query: timeRangeToQuery(timeRange, this.$route.query, defaultTimeRange),
      });
    },
  },
  created() {
    // This is to support the older URL <project>/-/environments/:env_id/metrics?dashboard=:path
    // and the new format <project>/-/metrics/:dashboardPath
    const encodedDashboard = this.$route.query.dashboard || this.$route.params.dashboard;
    const currentDashboard = encodedDashboard ? decodeURIComponent(encodedDashboard) : null;
    this.setCurrentDashboard({ currentDashboard });

    // Set initial time range or a default if none is provided
    this.setTimeRange(timeRangeFromParams(this.$route.query) || defaultTimeRange);
  },
  methods: {
    ...mapActions('monitoringDashboard', ['setCurrentDashboard', 'setTimeRange']),
  },
};
</script>
<template>
  <dashboard v-bind="{ ...dashboardProps }" />
</template>
