<script>
import Api from 'ee/api';
import { __, s__ } from '~/locale';
import createFlash from '~/flash';
import MetricCard from '../../shared/components/metric_card.vue';

export default {
  name: 'GroupActivityCard',
  components: {
    MetricCard,
  },
  props: {
    groupFullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
      metrics: {
        mergeRequests: { value: null, label: s__('GroupActivyMetrics|Merge Requests created') },
        issues: { value: null, label: s__('GroupActivyMetrics|Issues created') },
        newMembers: { value: null, label: s__('GroupActivityMetrics|New Members created') },
      },
    };
  },
  computed: {
    metricsArray() {
      return Object.entries(this.metrics).map(([key, obj]) => {
        const { value, label } = obj;
        return {
          key,
          value,
          label,
        };
      });
    },
  },
  created() {
    this.fetchMetrics(this.groupFullPath);
  },
  methods: {
    fetchMetrics(groupPath) {
      this.isLoading = true;

      return Promise.all([
        Api.groupActivityMergeRequestsCount(groupPath),
        Api.groupActivityIssuesCount(groupPath),
        Api.groupActivityNewMembersCount(groupPath),
      ])
        .then(([mrResponse, issuesResponse, newMembersResponse]) => {
          this.metrics.mergeRequests.value = mrResponse.data.merge_requests_count;
          this.metrics.issues.value = issuesResponse.data.issues_count;
          this.metrics.newMembers.value = newMembersResponse.data.new_members_count;
          this.isLoading = false;
        })
        .catch(() => {
          createFlash(__('Failed to load group activity metrics. Please try again.'));
          this.isLoading = false;
        });
    },
  },
};
</script>

<template>
  <metric-card
    :title="s__('GroupActivyMetrics|Recent activity (last 90 days)')"
    :metrics="metricsArray"
    :is-loading="isLoading"
  />
</template>
