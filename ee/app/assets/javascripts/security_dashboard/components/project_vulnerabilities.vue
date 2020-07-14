<script>
import { GlAlert, GlDeprecatedButton, GlIntersectionObserver } from '@gitlab/ui';
import VulnerabilityList from './vulnerability_list.vue';
import vulnerabilitiesQuery from '../graphql/project_vulnerabilities.graphql';
import { VULNERABILITIES_PER_PAGE } from '../store/constants';

export default {
  name: 'ProjectVulnerabilitiesApp',
  components: {
    GlAlert,
    GlDeprecatedButton,
    GlIntersectionObserver,
    VulnerabilityList,
  },
  props: {
    projectFullPath: {
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
      vulnerabilities: [],
      errorLoadingVulnerabilities: false,
    };
  },
  apollo: {
    vulnerabilities: {
      query: vulnerabilitiesQuery,
      variables() {
        return {
          fullPath: this.projectFullPath,
          first: VULNERABILITIES_PER_PAGE,
          ...this.filters,
        };
      },
      update: ({ project }) => project.vulnerabilities.nodes,
      result({ data }) {
        this.pageInfo = data.project.vulnerabilities.pageInfo;
      },
      error() {
        this.errorLoadingVulnerabilities = true;
      },
    },
  },
  computed: {
    isLoadingVulnerabilities() {
      return this.$apollo.queries.vulnerabilities.loading;
    },
    isLoadingFirstVulnerabilities() {
      return this.isLoadingVulnerabilities && this.vulnerabilities.length === 0;
    },
  },
  methods: {
    fetchNextPage() {
      if (this.pageInfo.hasNextPage) {
        this.$apollo.queries.vulnerabilities.fetchMore({
          variables: { after: this.pageInfo.endCursor },
          updateQuery: (previousResult, { fetchMoreResult }) => {
            const newResult = { ...fetchMoreResult };
            previousResult.project.vulnerabilities.nodes.push(
              ...fetchMoreResult.project.vulnerabilities.nodes,
            );
            newResult.project.vulnerabilities.nodes = previousResult.project.vulnerabilities.nodes;
            return newResult;
          },
        });
      }
    },
    refetchVulnerabilities() {
      this.$apollo.queries.vulnerabilities.refetch();
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="errorLoadingVulnerabilities" :dismissible="false" variant="danger">
      {{
        s__(
          'SecurityReports|Error fetching the vulnerability list. Please check your network connection and try again.',
        )
      }}
    </gl-alert>
    <vulnerability-list
      v-else
      :is-loading="isLoadingFirstVulnerabilities"
      :filters="filters"
      :vulnerabilities="vulnerabilities"
      :should-show-identifier="true"
      :should-show-report-type="true"
      @refetch-vulnerabilities="refetchVulnerabilities"
    />
    <gl-intersection-observer
      v-if="pageInfo.hasNextPage"
      class="text-center"
      @appear="fetchNextPage"
    >
      <gl-deprecated-button
        :loading="isLoadingVulnerabilities"
        :disabled="isLoadingVulnerabilities"
        @click="fetchNextPage"
        >{{ s__('SecurityReports|Load more vulnerabilities') }}</gl-deprecated-button
      >
    </gl-intersection-observer>
  </div>
</template>
