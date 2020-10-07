<script>
import InstanceCounts from './instance_counts.vue';
import IssuesAndMergeRequestsChart from './issues_and_merge_requests_chart.vue';
import { TOTAL_DATAPOINTS_TO_FETCH, TODAY, START_DATE } from '../constants';

export default {
  name: 'InstanceStatisticsApp',
  components: {
    InstanceCounts,
    IssuesAndMergeRequestsChart,
  },
  TOTAL_DATAPOINTS_TO_FETCH,
  TODAY,
  START_DATE,
};
</script>

<template>
  <div>
    <instance-counts />
    <issues-and-merge-requests-chart
      :start-date="$options.START_DATE"
      :end-date="$options.TODAY"
      :total-data-points="$options.TOTAL_DATAPOINTS_TO_FETCH"
    />
  </div>
</template>
