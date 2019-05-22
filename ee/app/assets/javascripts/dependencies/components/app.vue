<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlBadge, GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import Pagination from '~/vue_shared/components/pagination_links.vue';
import DependenciesActions from './dependencies_actions.vue';
import DependenciesTable from './dependencies_table.vue';
import DependencyListIncompleteAlert from './dependency_list_incomplete_alert.vue';
import DependencyListJobFailedAlert from './dependency_list_job_failed_alert.vue';

export default {
  name: 'DependenciesApp',
  components: {
    DependenciesActions,
    DependenciesTable,
    GlBadge,
    GlEmptyState,
    GlLoadingIcon,
    DependencyListIncompleteAlert,
    DependencyListJobFailedAlert,
    Pagination,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['jobNotSetUp', 'jobFailed', 'isIncomplete']),
    ...mapState([
      'initialized',
      'isLoading',
      'errorLoading',
      'dependencies',
      'pageInfo',
      'reportInfo',
    ]),
    shouldShowPagination() {
      return Boolean(!this.isLoading && !this.errorLoading && this.pageInfo && this.pageInfo.total);
    },
  },
  created() {
    this.setDependenciesEndpoint(this.endpoint);
    this.fetchDependencies();
  },
  methods: {
    ...mapActions(['setDependenciesEndpoint', 'fetchDependencies']),
    fetchPage(page) {
      this.fetchDependencies({ page });
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="!initialized" size="md" class="mt-4" />

  <!-- TODO: add correct documentation link and SVG path -->
  <gl-empty-state
    v-else-if="jobNotSetUp"
    :title="__('View dependency information for your project')"
    :description="
      __('The dependency list details information about the components used within your project.')
    "
    :primary-button-link="'#'"
    :primary-button-text="__('Learn more about the dependency list')"
  />

  <div v-else>
    <dependency-list-incomplete-alert v-if="isIncomplete" />

    <dependency-list-job-failed-alert v-if="jobFailed" :job-path="reportInfo.jobPath" />

    <div class="d-sm-flex justify-content-between align-items-baseline my-2">
      <h4 class="h5">
        {{ __('Dependencies') }}
        <gl-badge pill>{{ pageInfo.total }}</gl-badge>
      </h4>

      <dependencies-actions />
    </div>

    <dependencies-table :dependencies="dependencies" :is-loading="isLoading" />

    <pagination
      v-if="shouldShowPagination"
      :change="fetchPage"
      :page-info="pageInfo"
      class="justify-content-center prepend-top-default"
    />
  </div>
</template>
