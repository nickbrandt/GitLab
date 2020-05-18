<script>
import { __ } from '~/locale';
import MergeRequest from './merge_request.vue';
import EmptyState from './empty_state.vue';
import Pagination from './pagination.vue';

export default {
  name: 'ComplianceDashboard',
  components: {
    MergeRequest,
    EmptyState,
    Pagination,
  },
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
      required: true,
    },
  },
  computed: {
    hasMergeRequests() {
      return this.mergeRequests.length > 0;
    },
  },
  strings: {
    heading: __('Compliance Dashboard'),
    subheading: __('Here you will find recent merge request activity'),
  },
};
</script>

<template>
  <div v-if="hasMergeRequests" class="compliance-dashboard">
    <header class="my-3">
      <h4>{{ $options.strings.heading }}</h4>
      <p>{{ $options.strings.subheading }}</p>
    </header>
    <ul class="content-list issuable-list issues-list">
      <merge-request v-for="mr in mergeRequests" :key="mr.id" :merge-request="mr" />
    </ul>
    <pagination class="my-3" :is-last-page="isLastPage" />
  </div>
  <empty-state v-else :image-path="emptyStateSvgPath" />
</template>
