<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { isEmpty } from 'lodash';

import { sprintf, __, s__ } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';

import Approvers from './approvers.vue';
import EmptyState from './empty_state.vue';
import MergeRequest from './merge_request.vue';
import Pagination from './pagination.vue';
import PipelineStatus from './pipeline_status.vue';
import GridColumnHeading from './grid_column_heading.vue';

export default {
  name: 'ComplianceDashboard',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    Approvers,
    EmptyState,
    GridColumnHeading,
    MergeRequest,
    Pagination,
    PipelineStatus,
  },
  mixins: [timeagoMixin],
  props: {
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    mergeRequests: {
      type: Array,
      required: true,
    },
    isLastPage: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    hasMergeRequests() {
      return this.mergeRequests.length > 0;
    },
  },
  methods: {
    key(id, value) {
      return `${id}-${value}`;
    },
    timeAgoString(mergedAt) {
      return sprintf(s__('merged %{timeAgo}'), {
        timeAgo: this.timeFormatted(mergedAt),
      });
    },
    timeTooltip(mergedAt) {
      return this.tooltipTitle(mergedAt);
    },
    hasPipeline(status) {
      return !isEmpty(status);
    },
  },
  strings: {
    heading: __('Compliance Dashboard'),
    subheading: __('Here you will find recent merge request activity'),
    mergeRequestLabel: __('Merge Request'),
    pipelineStatusLabel: __('Pipeline'),
    updatesLabel: __('Updates'),
  },
};
</script>

<template>
  <div v-if="hasMergeRequests" class="compliance-dashboard">
    <header class="gl-my-5">
      <h4>{{ $options.strings.heading }}</h4>
      <p>{{ $options.strings.subheading }}</p>
    </header>
    <div class="dashboard-grid">
      <grid-column-heading :heading="$options.strings.mergeRequestLabel" />
      <grid-column-heading :heading="$options.strings.pipelineStatusLabel" class="gl-text-center" />
      <grid-column-heading :heading="$options.strings.updatesLabel" class="gl-text-right" />

      <template v-for="mergeRequest in mergeRequests">
        <merge-request :key="key(mergeRequest.id, 'MR')" :merge-request="mergeRequest" />

        <div
          :key="key(mergeRequest.id, 'pipeline')"
          class="dashboard-pipeline gl-display-flex gl-align-items-center gl-justify-content-center gl-border-b-solid gl-border-b-1 gl-border-b-gray-100 gl-p-5"
        >
          <pipeline-status
            v-if="hasPipeline(mergeRequest.pipeline_status)"
            :status="mergeRequest.pipeline_status"
          />
        </div>

        <div
          :key="key(mergeRequest.id, 'updates')"
          class="gl-text-right gl-border-b-solid gl-border-b-1 gl-border-b-gray-100 gl-p-5 gl-relative"
        >
          <approvers :approvers="mergeRequest.approved_by_users" />
          <span class="gl-text-gray-700">
            <time v-gl-tooltip.bottom="timeTooltip(mergeRequest.merged_at)">{{
              timeAgoString(mergeRequest.merged_at)
            }}</time>
          </span>
        </div>
      </template>
    </div>
    <pagination :is-last-page="isLastPage" />
  </div>
  <empty-state v-else :image-path="emptyStateSvgPath" />
</template>
