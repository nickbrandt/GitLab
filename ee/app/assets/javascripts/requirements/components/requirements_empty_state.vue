<script>
import { GlEmptyState } from '@gitlab/ui';

import { FilterStateEmptyMessage } from '../constants';

export default {
  components: {
    GlEmptyState,
  },
  props: {
    filterBy: {
      type: String,
      required: true,
    },
    emptyStatePath: {
      type: String,
      required: true,
    },
  },
  computed: {
    emptyStateTitle() {
      return FilterStateEmptyMessage[this.filterBy];
    },
  },
};
</script>

<template>
  <div class="requirements-empty-state-container">
    <gl-empty-state :title="emptyStateTitle" :svg-path="emptyStatePath" />
  </div>
</template>
