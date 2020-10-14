<script>
import RepoTab from './repo_tab.vue';

export default {
  components: {
    RepoTab,
  },
  props: {
    activeFile: {
      type: Object,
      required: true,
    },
    files: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <div class="multi-file-tabs">
    <ul ref="tabsScroller" class="list-unstyled gl-mb-0">
      <repo-tab v-for="tab in files" :key="tab.key" :tab="tab" />
    </ul>
  </div>
</template>
