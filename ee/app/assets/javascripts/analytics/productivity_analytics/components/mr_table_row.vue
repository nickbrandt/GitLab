<script>
import { sprintf, __, n__ } from '~/locale';
import { GlLink, GlAvatar } from '@gitlab/ui';

export default {
  components: {
    GlLink,
    GlAvatar,
  },
  props: {
    mergeRequest: {
      type: Object,
      required: true,
    },
    metricType: {
      type: String,
      required: true,
    },
    metricLabel: {
      type: String,
      required: true,
    },
  },
  computed: {
    mrId() {
      return `!${this.mergeRequest.iid}`;
    },
    commitCount() {
      return n__('%d commit', '%d commits', this.mergeRequest.commits_count);
    },
    locPerCommit() {
      return sprintf(__('%{count} LOC/commit'), { count: this.mergeRequest.loc_per_commit });
    },
    filesTouched() {
      return sprintf(__('%{count} files touched'), { count: this.mergeRequest.files_touched });
    },
    selectedMetric() {
      return this.mergeRequest[this.metricType];
    },
    metricTimeUnit() {
      return this.metricType === 'days_to_merge'
        ? n__('day', 'days', this.selectedMetric)
        : n__('Time|hr', 'Time|hrs', this.selectedMetric);
    },
  },
};
</script>
<template>
  <div class="gl-responsive-table-row-layout gl-responsive-table-row">
    <div
      class="table-section section-50 d-flex flex-row-reverse flex-md-row justify-content-between justify-content-md-start qa-mr-details"
    >
      <div>
        <gl-avatar :src="mergeRequest.author_avatar_url" :size="16" />
      </div>
      <div class="mw-90p">
        <h5 class="item-title mr-title my-0 mw-90p d-block str-truncated">
          <gl-link :href="mergeRequest.merge_request_url" target="_blank">{{
            mergeRequest.title
          }}</gl-link>
        </h5>
        <ul class="horizontal-list list-items-separated text-secondary">
          <li>{{ mrId }}</li>
          <li>{{ commitCount }}</li>
          <li>{{ locPerCommit }}</li>
          <li>{{ filesTouched }}</li>
        </ul>
      </div>
    </div>
    <div class="table-section section-50 d-flex flex-row align-items-start qa-mr-metrics">
      <div class="metric-col">
        <span class="time">
          {{ mergeRequest.time_to_merge }}
          <span> {{ n__('Time|hr', 'Time|hrs', mergeRequest.time_to_merge) }} </span>
        </span>
        <span class="d-flex d-md-none text-secondary metric-label">{{ __('Time to merge') }}</span>
      </div>
      <div class="metric-col">
        <span class="time">
          {{ selectedMetric }}
          <span> {{ metricTimeUnit }} </span>
        </span>
        <span class="d-flex d-md-none text-secondary metric-label">{{ metricLabel }}</span>
      </div>
    </div>
  </div>
</template>
