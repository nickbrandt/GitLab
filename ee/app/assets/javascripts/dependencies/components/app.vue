<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlBadge, GlEmptyState, GlLoadingIcon, GlTab, GlTabs } from '@gitlab/ui';
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
    GlTab,
    GlTabs,
    DependencyListIncompleteAlert,
    DependencyListJobFailedAlert,
    PaginatedDependenciesTable,
  },
  inject: {
    dependencyListVulnerabilities: {
      from: 'dependencyListVulnerabilities',
      default: false,
    },
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
    ...mapState(['currentList', 'listTypes']),
    ...mapGetters([
      'isInitialized',
      'isJobNotSetUp',
      'isJobFailed',
      'isIncomplete',
      'reportInfo',
      'totals',
    ]),
    ...mapState(DEPENDENCY_LIST_TYPES.all.namespace, ['pageInfo']),
    currentListIndex: {
      get() {
        return this.listTypes.map(({ namespace }) => namespace).indexOf(this.currentList);
      },
      set(index) {
        const { namespace } = this.listTypes[index] || {};
        this.setCurrentList(namespace);
      },
    },
  },
  created() {
    this.setDependenciesEndpoint(this.endpoint);
    this.fetchDependencies();
  },
  methods: {
    ...mapActions(['setDependenciesEndpoint', 'fetchDependencies', 'setCurrentList']),
    dismissIncompleteListAlert() {
      this.isIncompleteAlertDismissed = true;
    },
    dismissJobFailedAlert() {
      this.isJobFailedAlertDismissed = true;
    },
    isTabDisabled(namespace) {
      return this.totals[namespace] <= 0;
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="!isInitialized" size="md" class="mt-4" />

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

    <template v-if="dependencyListVulnerabilities">
      <h3 class="h5">{{ __('Dependencies') }}</h3>

      <gl-tabs v-model="currentListIndex">
        <gl-tab
          v-for="listType in listTypes"
          :key="listType.namespace"
          :disabled="isTabDisabled(listType.namespace)"
        >
          <template v-slot:title>
            {{ listType.label }}
            <gl-badge pill>{{ totals[listType.namespace] }}</gl-badge>
          </template>
          <paginated-dependencies-table :namespace="listType.namespace" />
        </gl-tab>
        <template v-slot:tabs>
          <li class="d-flex align-items-center ml-sm-auto">
            <dependencies-actions :namespace="currentList" class="my-2 my-sm-0" />
          </li>
        </template>
      </gl-tabs>
    </template>

    <template v-else>
      <div class="d-sm-flex justify-content-between align-items-baseline my-2">
        <h3 class="h5">
          {{ __('Dependencies') }}
          <gl-badge v-if="pageInfo.total" pill data-qa-selector="dependency_list_total_content">{{
            pageInfo.total
          }}</gl-badge>
        </h3>

        <dependencies-actions :namespace="currentList" />
      </div>

      <paginated-dependencies-table :namespace="currentList" />
    </template>
  </div>
</template>
