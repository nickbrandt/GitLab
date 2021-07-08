<script>
import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlLoadingIcon } from '@gitlab/ui';

import { __ } from '~/locale';
import getProjectQuery from '../../graphql/queries/get_project.query.graphql';

export default {
  BRANCHES_PER_PAGE: 20,
  components: {
    GlDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
    GlLoadingIcon,
  },
  props: {
    selectedProject: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      sourceBranchSearchQuery: '',
      initialSourceBranchNamesLoading: false,
      sourceBranchNamesLoading: false,
      sourceBranchNames: [],
    };
  },
  computed: {
    hasSelectedSourceBranch() {
      return Boolean(this.selectedSourceBranchName);
    },
    branchDropdownText() {
      return this.selectedSourceBranchName || __('Select a branch');
    },
  },
  watch: {
    async selectedProject() {
      this.onSourceBranchSelect(null);

      this.initialSourceBranchNamesLoading = true;
      await this.fetchSourceBranchNames({ projectPath: this.selectedProject.fullPath });
      this.initialSourceBranchNamesLoading = false;
    },
  },
  methods: {
    onSourceBranchSelect(branchName) {
      this.$emit('change', branchName);
    },
    onSourceBranchSearchQuery(branchSearchQuery) {
      this.branchSearchQuery = branchSearchQuery;
      this.fetchSourceBranchNames({
        projectPath: this.selectedProject.fullPath,
        searchPattern: this.branchSearchQuery,
      });
    },
    onError(err) {
      this.$emit('error', err);
    },
    async fetchSourceBranchNames({ projectPath, searchPattern = '*' } = {}) {
      this.sourceBranchNamesLoading = true;
      try {
        const { data } = await this.$apollo.query({
          query: getProjectQuery,
          variables: {
            projectPath,
            branchNamesLimit: this.$options.BRANCHES_PER_PAGE,
            branchNamesOffset: 0,
            branchNamesSearchPattern: `*${searchPattern}*`,
          },
        });

        const { branchNames, rootRef } = data?.project.repository || {};
        this.sourceBranchNames = branchNames || [];
        // use root ref as the default selection
        if (!this.hasSelectedSourceBranch) {
          this.selectedSourceBranchName = rootRef;
        }
      } catch (err) {
        this.onError({
          title: 'Something went wrong while fetching source branches.',
          message: err.message,
        });
      } finally {
        this.sourceBranchNamesLoading = false;
      }
    },
  },
};
</script>

<template>
  <gl-dropdown
    :text="branchDropdownText"
    :loading="initialSourceBranchNamesLoading"
    :disabled="!hasSelectedProject"
    :class="{ 'gl-font-monospace': hasSelectedSourceBranch }"
  >
    <template #header>
      <gl-search-box-by-type
        :debounce="250"
        :value="sourceBranchSearchQuery"
        @input="onSourceBranchSearchQuery"
      />
    </template>

    <gl-loading-icon v-show="sourceBranchNamesLoading" />
    <gl-dropdown-item
      v-for="branchName in sourceBranchNames"
      v-show="!sourceBranchNamesLoading"
      :key="branchName"
      :is-checked="branchName === selectedSourceBranchName"
      is-check-item
      class="gl-font-monospace"
      @click="onSourceBranchSelect(branchName)"
    >
      {{ branchName }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
