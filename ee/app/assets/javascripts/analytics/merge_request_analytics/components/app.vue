<script>
import ThroughputChart from './throughput_chart.vue';

export default {
  name: 'MergeRequestAnalyticsApp',
  components: {
    ThroughputChart,
  },
};
</script>
<template>
  <div>
    <h3 data-testid="pageTitle" class="gl-mb-5">{{ __('Merge Request Analytics') }}</h3>
    <throughput-chart />
  </div>
</template>
