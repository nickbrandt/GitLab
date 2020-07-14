<script>
import Api from 'ee/api';
import { __, s__ } from '~/locale';
import createFlash from '~/flash';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import MetricCard from '../../shared/components/metric_card.vue';

const REPORT_PAGE_CONFIGURATION = {
  mergeRequests: {
    id: 'recent_merge_requests_by_group',
  },
};

export default {
  name: 'GroupActivityCard',
  components: {
    MetricCard,
  },
  inject: ['groupFullPath', 'groupName', 'reportPagesPath', 'enableReportPages'],
  data() {
    return {
      isLoading: false,
      metrics: {
        mergeRequests: {
          value: null,
          label: s__('GroupActivityMetrics|Merge Requests opened'),
        },
        issues: { value: null, label: s__('GroupActivityMetrics|Issues opened') },
        newMembers: { value: null, label: s__('GroupActivityMetrics|Members added') },
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
          link: this.generateReportPageLink(key),
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
    displayReportLink(key) {
      return this.enableReportPages && Object.keys(REPORT_PAGE_CONFIGURATION).includes(key);
    },
    generateReportPageLink(key) {
      return this.displayReportLink(key)
        ? mergeUrlParams(
            {
              groupPath: this.groupFullPath,
              groupName: this.groupName,
              reportId: REPORT_PAGE_CONFIGURATION[key].id,
            },
            this.reportPagesPath,
          )
        : null;
    },
  },
};
</script>

<template>
  <metric-card
    :title="s__('GroupActivityMetrics|Recent activity (last 90 days)')"
    :metrics="metricsArray"
    :is-loading="isLoading"
  />
</template>
