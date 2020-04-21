<script>
import { GlAlert, GlButton, GlEmptyState, GlIntersectionObserver, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { fetchPolicies } from '~/lib/graphql';
import VulnerabilityList from 'ee/vulnerabilities/components/vulnerability_list.vue';
import vulnerabilitiesQuery from '../graphql/instance_vulnerabilities.graphql';
import { VULNERABILITIES_PER_PAGE } from 'ee/vulnerabilities/constants';

export default {
  components: {
    GlAlert,
    GlButton,
    GlEmptyState,
    GlIntersectionObserver,
    GlLoadingIcon,
    VulnerabilityList,
  },
  props: {
    dashboardDocumentation: {
      type: String,
      required: true,
    },
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    filters: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      pageInfo: {},
      isFirstResultLoading: true,
      vulnerabilities: [],
      errorLoadingVulnerabilities: false,
    };
  },
  computed: {
    isQueryLoading() {
      return this.$apollo.queries.vulnerabilities.loading;
    },
  },
  apollo: {
    vulnerabilities: {
      query: vulnerabilitiesQuery,
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      variables() {
        return {
          first: VULNERABILITIES_PER_PAGE,
          ...this.filters,
        };
      },
      update: ({ vulnerabilities }) => vulnerabilities.nodes,
      result({ data, loading }) {
        this.isFirstResultLoading = loading;
        this.pageInfo = data.vulnerabilities.pageInfo;
      },
      error() {
        this.errorLoadingVulnerabilities = true;
      },
    },
  },
  methods: {
    onErrorDismiss() {
      this.errorLoadingVulnerabilities = false;
    },
    fetchNextPage() {
      if (this.pageInfo.hasNextPage) {
        this.$apollo.queries.vulnerabilities.fetchMore({
          variables: { after: this.pageInfo.endCursor },
          updateQuery: (previousResult, { fetchMoreResult }) => {
            fetchMoreResult.vulnerabilities.nodes.unshift(...previousResult.vulnerabilities.nodes);
            return fetchMoreResult;
          },
        });
      }
    },
  },
  emptyStateDescription: s__(
    `While it's rare to have no vulnerabilities, it can happen. In any event, we ask that you please double check your settings to make sure you've set up your dashboard correctly.`,
  ),
};
</script>

<template>
  <div>
    <gl-alert
      v-if="errorLoadingVulnerabilities"
      class="mb-4"
      variant="danger"
      @dismiss="onErrorDismiss"
    >
      {{
        s__(
          'Security Dashboard|Error fetching the vulnerability list. Please check your network connection and try again.',
        )
      }}
    </gl-alert>
    <vulnerability-list
      v-else
      :is-loading="isFirstResultLoading"
      :dashboard-documentation="dashboardDocumentation"
      :empty-state-svg-path="emptyStateSvgPath"
      :vulnerabilities="vulnerabilities"
      should-show-project-namespace
    >
      <template #emptyState>
        <gl-empty-state
          :title="s__(`SecurityDashboard|No vulnerabilities found for dashboard`)"
          :svg-path="emptyStateSvgPath"
          :description="$options.emptyStateDescription"
          :primary-button-link="dashboardDocumentation"
          :primary-button-text="s__('Security Reports|Learn more about setting up your dashboard')"
        />
      </template>
    </vulnerability-list>
    <gl-intersection-observer
      v-if="pageInfo.hasNextPage"
      class="text-center"
      @appear="fetchNextPage"
    >
      <gl-button :disabled="isFirstResultLoading" @click="fetchNextPage">
        <gl-loading-icon v-if="isQueryLoading" size="md" />
        <template v-else>{{ __('Load more vulnerabilities') }}</template>
      </gl-button>
    </gl-intersection-observer>
  </div>
</template>
