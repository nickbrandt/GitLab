<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { isEmpty } from 'lodash';

import { sprintf, __ } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';

import ApprovalStatus from './approval_status.vue';
import Approvers from './approvers.vue';
import BranchDetails from './branch_details.vue';
import MergeRequest from './merge_request.vue';
import PipelineStatus from './pipeline_status.vue';
import GridColumnHeading from '../shared/grid_column_heading.vue';
import Pagination from '../shared/pagination.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    ApprovalStatus,
    Approvers,
    BranchDetails,
    GridColumnHeading,
    MergeRequest,
    PipelineStatus,
    Pagination,
  },
  mixins: [timeagoMixin],
  props: {
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
  methods: {
    key(id, value) {
      return `${id}-${value}`;
    },
    timeAgoString(mergedAt) {
      return sprintf(__('merged %{timeAgo}'), {
        timeAgo: this.timeFormatted(mergedAt),
      });
    },
    timeTooltip(mergedAt) {
      return this.tooltipTitle(mergedAt);
    },
    hasStatus(status) {
      return !isEmpty(status);
    },
    hasBranchDetails(mergeRequest) {
      return mergeRequest.target_branch && mergeRequest.source_branch;
    },
  },
  strings: {
    mergeRequestLabel: __('Merge Request'),
    approvalStatusLabel: __('Approval Status'),
    pipelineStatusLabel: __('Pipeline'),
    updatesLabel: __('Updates'),
  },
  keyTypes: {
    mergeRequest: 'MR',
    approvalStatus: 'approvalStatus',
    pipeline: 'pipeline',
    updates: 'updates',
  },
};
</script>

<template>
  <div>
    <div class="dashboard-grid gl-display-grid gl-grid-tpl-rows-auto">
      <grid-column-heading :heading="$options.strings.mergeRequestLabel" />
      <grid-column-heading :heading="$options.strings.approvalStatusLabel" class="gl-text-center" />
      <grid-column-heading :heading="$options.strings.pipelineStatusLabel" class="gl-text-center" />
      <grid-column-heading :heading="$options.strings.updatesLabel" class="gl-text-right" />

      <template v-for="mergeRequest in mergeRequests">
        <merge-request
          :key="key(mergeRequest.id, $options.keyTypes.mergeRequest)"
          :merge-request="mergeRequest"
        />

        <div
          :key="key(mergeRequest.id, $options.keyTypes.approvalStatus)"
          class="gl-display-flex gl-align-items-center gl-justify-content-center gl-border-b-solid gl-border-b-1 gl-border-b-gray-100 gl-p-5"
        >
          <approval-status
            v-if="hasStatus(mergeRequest.approval_status)"
            :status="mergeRequest.approval_status"
          />
        </div>
        <div
          :key="key(mergeRequest.id, $options.keyTypes.pipeline)"
          class="dashboard-pipeline gl-display-flex gl-align-items-center gl-justify-content-center gl-border-b-solid gl-border-b-1 gl-border-b-gray-100 gl-p-5"
        >
          <pipeline-status
            v-if="hasStatus(mergeRequest.pipeline_status)"
            :status="mergeRequest.pipeline_status"
          />
        </div>

        <div
          :key="key(mergeRequest.id, $options.keyTypes.updates)"
          class="gl-text-right gl-border-b-solid gl-border-b-1 gl-border-b-gray-100 gl-p-5 gl-relative"
        >
          <approvers :approvers="mergeRequest.approved_by_users" />
          <branch-details
            v-if="hasBranchDetails(mergeRequest)"
            :source-branch="{
              name: mergeRequest.source_branch,
              uri: mergeRequest.source_branch_uri,
            }"
            :target-branch="{
              name: mergeRequest.target_branch,
              uri: mergeRequest.target_branch_uri,
            }"
          />
          <span class="gl-text-gray-700">
            <time v-gl-tooltip.bottom="timeTooltip(mergeRequest.merged_at)">{{
              timeAgoString(mergeRequest.merged_at)
            }}</time>
          </span>
        </div>
      </template>
    </div>

    <pagination class="gl-mt-5" :is-last-page="isLastPage" />
  </div>
</template>
