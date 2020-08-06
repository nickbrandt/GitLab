<script>
import VulnerabilityChart from './first_class_vulnerability_chart.vue';
import VulnerabilitySeverity from './vulnerability_severity.vue';
import vulnerabilityHistoryQuery from '../graphql/group_vulnerability_history.query.graphql';
import SecurityChartsLayout from './security_charts_layout.vue';

export default {
  components: {
    SecurityChartsLayout,
    VulnerabilitySeverity,
    VulnerabilityChart,
  },
  props: {
    groupFullPath: {
      type: String,
      required: true,
    },
    vulnerableProjectsEndpoint: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      vulnerabilityHistoryQuery,
    };
  },
};
</script>

<template>
  <security-charts-layout>
    <vulnerability-chart :query="vulnerabilityHistoryQuery" :group-full-path="groupFullPath" />
    <vulnerability-severity :endpoint="vulnerableProjectsEndpoint" />
  </security-charts-layout>
</template>
