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
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    documentationPath: {
      type: String,
      required: true,
    },
    dependencyListVulnerabilities: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isIncompleteAlertDismissed: false,
      isJobFailedAlertDismissed: false,
    };
  },
  computed: {
    ...mapGetters(['isJobNotSetUp', 'isJobFailed', 'isIncomplete']),
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
    dismissIncompleteListAlert() {
      this.isIncompleteAlertDismissed = true;
    },
    dismissJobFailedAlert() {
      this.isJobFailedAlertDismissed = true;
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="!initialized" size="md" class="mt-4" />

  <gl-empty-state
    v-else-if="isJobNotSetUp"
    :title="__('View dependency details for your project')"
    :description="
      __('The dependency list details information about the components used within your project.')
    "
    :svg-path="emptyStateSvgPath"
    :primary-button-link="documentationPath"
    :primary-button-text="__('Learn more about the dependency list')"
  />

  <div v-else>
    <dependency-list-incomplete-alert
      v-if="isIncomplete && !isIncompleteAlertDismissed"
      @close="dismissIncompleteListAlert"
    />

    <dependency-list-job-failed-alert
      v-if="isJobFailed && !isJobFailedAlertDismissed"
      :job-path="reportInfo.jobPath"
      @close="dismissJobFailedAlert"
    />

    <div class="d-sm-flex justify-content-between align-items-baseline my-2">
      <h4 class="h5">
        {{ __('Dependencies') }}
        <gl-badge v-if="pageInfo.total" pill>{{ pageInfo.total }}</gl-badge>
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
