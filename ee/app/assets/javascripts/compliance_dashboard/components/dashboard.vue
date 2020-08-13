<script>
import Cookies from 'js-cookie';
import { GlTabs, GlTab } from '@gitlab/ui';
import { __ } from '~/locale';
import MergeRequestsGrid from './merge_requests/grid.vue';
import EmptyState from './empty_state.vue';
import { COMPLIANCE_TAB_COOKIE_KEY } from '../constants';

export default {
  name: 'ComplianceDashboard',
  components: {
    MergeRequestsGrid,
    EmptyState,
    GlTab,
    GlTabs,
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
    showTabs() {
      return Cookies.get(COMPLIANCE_TAB_COOKIE_KEY) === 'true';
    },
  },
  strings: {
    heading: __('Compliance Dashboard'),
    subheading: __('Here you will find recent merge request activity'),
    mergeRequestsTabLabel: __('Merge Requests'),
  },
};
</script>

<template>
  <div v-if="hasMergeRequests" class="compliance-dashboard">
    <header class="gl-my-5">
      <h4>{{ $options.strings.heading }}</h4>
      <p>{{ $options.strings.subheading }}</p>
    </header>

    <gl-tabs v-if="showTabs()">
      <gl-tab>
        <template #title>
          <span>{{ $options.strings.mergeRequestsTabLabel }}</span>
        </template>
        <merge-requests-grid :merge-requests="mergeRequests" :is-last-page="isLastPage" />
      </gl-tab>
    </gl-tabs>
    <merge-requests-grid v-else :merge-requests="mergeRequests" :is-last-page="isLastPage" />
  </div>
  <empty-state v-else :image-path="emptyStateSvgPath" />
</template>
