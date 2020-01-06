<script>
import { mapState } from 'vuex';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { engineeringNotation } from '@gitlab/ui/src/utils/number_utils';

import { ANOMALOUS_REQUESTS, TOTAL_REQUESTS } from './constants';

export default {
  name: 'WafStatisticsSummary',
  components: {
    GlSingleStat,
  },
  computed: {
    ...mapState('threatMonitoring', ['wafStatistics']),
    statistics() {
      return [
        {
          key: 'anomalousTraffic',
          title: ANOMALOUS_REQUESTS,
          value: `${Math.round(this.wafStatistics.anomalousTraffic * 100)}%`,
          variant: 'warning',
        },
        {
          key: 'totalTraffic',
          title: TOTAL_REQUESTS,
          value: engineeringNotation(this.wafStatistics.totalTraffic),
          variant: 'secondary',
        },
      ];
    },
  },
};
</script>

<template>
  <div class="row">
    <gl-single-stat
      v-for="stat in statistics"
      :key="stat.key"
      class="col-sm-6 col-md-4 col-lg-3"
      v-bind="stat"
    />
  </div>
</template>
