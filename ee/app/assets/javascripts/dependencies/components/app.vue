<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlBadge, GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import DependenciesActions from './dependencies_actions.vue';
import DependencyListIncompleteAlert from './dependency_list_incomplete_alert.vue';
import DependencyListJobFailedAlert from './dependency_list_job_failed_alert.vue';
import PaginatedDependenciesTable from './paginated_dependencies_table.vue';
import { DEPENDENCY_LIST_TYPES } from '../store/constants';

export default {
  name: 'DependenciesApp',
  components: {
    DependenciesActions,
    GlBadge,
    GlEmptyState,
    GlLoadingIcon,
    DependencyListIncompleteAlert,
    DependencyListJobFailedAlert,
    PaginatedDependenciesTable,
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
  },
  data() {
    return {
      isIncompleteAlertDismissed: false,
      isJobFailedAlertDismissed: false,
    };
  },
  computed: {
    ...mapState(['currentList']),
    ...mapGetters(DEPENDENCY_LIST_TYPES.all, ['isJobNotSetUp', 'isJobFailed', 'isIncomplete']),
    ...mapState(DEPENDENCY_LIST_TYPES.all, ['initialized', 'pageInfo', 'reportInfo']),
  },
  created() {
    this.setDependenciesEndpoint(this.endpoint);
    this.fetchDependencies();
  },
  methods: {
    ...mapActions(DEPENDENCY_LIST_TYPES.all, ['setDependenciesEndpoint', 'fetchDependencies']),
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

      <dependencies-actions :namespace="currentList" />
    </div>

    <paginated-dependencies-table :namespace="currentList" />
  </div>
</template>
