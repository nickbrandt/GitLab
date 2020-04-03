<script>
import { GlSkeletonLoading } from '@gitlab/ui';

import { DEFAULT_PAGE_SIZE } from '../constants';

export default {
  components: {
    GlSkeletonLoading,
  },
  props: {
    filterBy: {
      type: String,
      required: true,
    },
    currentTabCount: {
      type: Number,
      required: true,
    },
    currentPage: {
      type: Number,
      required: true,
    },
  },
  computed: {
    lastPage() {
      return Math.ceil(this.currentTabCount / DEFAULT_PAGE_SIZE);
    },
    loaderCount() {
      if (this.currentTabCount > DEFAULT_PAGE_SIZE && this.currentPage !== this.lastPage) {
        return DEFAULT_PAGE_SIZE;
      }
      return this.currentTabCount % DEFAULT_PAGE_SIZE || DEFAULT_PAGE_SIZE;
    },
  },
};
</script>

<template>
  <ul class="content-list issuable-list issues-list requirements-list-loading">
    <li v-for="(i, index) in Array(loaderCount).fill()" :key="index" class="issue requirement">
      <gl-skeleton-loading :lines="2" class="pt-2" />
    </li>
  </ul>
</template>
