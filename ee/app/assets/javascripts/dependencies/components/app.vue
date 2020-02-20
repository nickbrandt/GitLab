<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlBadge, GlEmptyState, GlLoadingIcon, GlTab, GlTabs, GlLink, GlButton } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import DependenciesActions from './dependencies_actions.vue';
import DependencyListIncompleteAlert from './dependency_list_incomplete_alert.vue';
import DependencyListJobFailedAlert from './dependency_list_job_failed_alert.vue';
import PaginatedDependenciesTable from './paginated_dependencies_table.vue';
import { DEPENDENCY_LIST_TYPES } from '../store/constants';
import { REPORT_STATUS } from '../store/modules/list/constants';

export default {
  name: 'DependenciesApp',
  components: {
    DependenciesActions,
    GlBadge,
    GlEmptyState,
    GlLoadingIcon,
    GlTab,
    GlTabs,
    GlLink,
    GlButton,
    DependencyListIncompleteAlert,
    DependencyListJobFailedAlert,
    Icon,
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
    supportDocumentationPath: {
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
      'generatedAtTimeAgo',
      'isInitialized',
      'isJobNotSetUp',
      'isJobFailed',
      'isIncomplete',
      'hasNoDependencies',
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
    subHeadingText() {
      const { jobPath } = this.reportInfo;

      const body = __(
        'Displays dependencies and known vulnerabilities, based on the %{linkStart}latest pipeline%{linkEnd} scan',
      );

      const linkStart = jobPath ? `<a href="${jobPath}">` : '';
      const linkEnd = jobPath ? '</a>' : '';

      return sprintf(body, { linkStart, linkEnd }, false);
    },
    showEmptyState() {
      return this.isJobNotSetUp || this.hasNoDependencies;
    },
    emptyStateOptions() {
      const map = {
        [REPORT_STATUS.jobNotSetUp]: {
          title: __('View dependency details for your project'),
          description: __(
            'The dependency list details information about the components used within your project.',
          ),
          buttonLabel: __('Learn more about the dependency list'),
          link: this.documentationPath,
        },
        [REPORT_STATUS.noDependencies]: {
          title: __('Dependency List has no entries'),
          description: __(
            'It seems like the Dependency Scanning job ran successfully, but no dependencies have been detected in your project.',
          ),
          buttonLabel: __('View supported languages and frameworks'),
          link: this.supportDocumentationPath,
        },
      };
      return map[this.reportInfo.status];
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
    qaCountSelector(label) {
      return `dependency_list_${label.toLowerCase().replace(' ', '_')}_count`;
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="!isInitialized" size="md" class="mt-4" />

  <gl-empty-state
    v-else-if="showEmptyState"
    :title="emptyStateOptions.title"
    :description="emptyStateOptions.description"
    :svg-path="emptyStateSvgPath"
  >
    <template #actions>
      <gl-button variant="info" :href="emptyStateOptions.link">
        {{ emptyStateOptions.buttonLabel }}
      </gl-button>
    </template>
  </gl-empty-state>

  <section v-else>
    <dependency-list-incomplete-alert
      v-if="isIncomplete && !isIncompleteAlertDismissed"
      @dismiss="dismissIncompleteListAlert"
    />

    <dependency-list-job-failed-alert
      v-if="isJobFailed && !isJobFailedAlertDismissed"
      :job-path="reportInfo.jobPath"
      @dismiss="dismissJobFailedAlert"
    />

    <header class="my-3">
      <h2 class="h4 mb-1">
        {{ __('Dependencies') }}
        <gl-link
          target="_blank"
          :href="documentationPath"
          :aria-label="__('Dependencies help page link')"
        >
          <icon name="question" />
        </gl-link>
      </h2>
      <p class="mb-0">
        <span v-html="subHeadingText"></span>
        <span v-if="generatedAtTimeAgo">
          <span aria-hidden="true">&bull;</span>
          <span class="text-secondary">{{ generatedAtTimeAgo }}</span>
        </span>
      </p>
    </header>

    <gl-tabs v-model="currentListIndex" content-class="pt-0">
      <gl-tab
        v-for="listType in listTypes"
        :key="listType.namespace"
        :disabled="isTabDisabled(listType.namespace)"
      >
        <template #title>
          {{ listType.label }}
          <gl-badge pill :data-qa-selector="qaCountSelector(listType.label)">
            {{ totals[listType.namespace] }}
          </gl-badge>
        </template>
        <paginated-dependencies-table :namespace="listType.namespace" />
      </gl-tab>
      <template #tabs-end>
        <li class="d-flex align-items-center ml-sm-auto">
          <dependencies-actions :namespace="currentList" class="my-2 my-sm-0" />
        </li>
      </template>
    </gl-tabs>
  </section>
</template>
