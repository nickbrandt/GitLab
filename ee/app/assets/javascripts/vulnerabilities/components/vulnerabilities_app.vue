<script>
import { mapActions, mapState } from 'vuex';
import { s__ } from '~/locale';
import { GlAlert, GlEmptyState } from '@gitlab/ui';
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';
import VulnerabilityList from 'ee/vulnerabilities/components/vulnerability_list.vue';

export default {
  name: 'VulnerabilitiesApp',
  components: {
    GlAlert,
    GlEmptyState,
    PaginationLinks,
    VulnerabilityList,
  },
  props: {
    vulnerabilitiesEndpoint: {
      type: String,
      required: true,
    },
    dashboardDocumentation: {
      type: String,
      required: true,
    },
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState('vulnerabilities', [
      'errorLoadingVulnerabilities',
      'isLoadingVulnerabilities',
      'pageInfo',
      'vulnerabilities',
    ]),
    ...mapState('filters', ['activeFilters']),
  },
  created() {
    this.setVulnerabilitiesEndpoint(this.vulnerabilitiesEndpoint);
    this.fetchVulnerabilities();
  },
  methods: {
    ...mapActions('vulnerabilities', ['setVulnerabilitiesEndpoint', 'fetchVulnerabilities']),
    fetchPage(page) {
      this.fetchVulnerabilities({ ...this.activeFilters, page });
    },
  },
  emptyStateDescription: s__(
    `While it's rare to have no vulnerabilities for your project, it can happen. In any event, we ask that you double check your settings to make sure you've set up your dashboard correctly.`,
  ),
};
</script>

<template>
  <div>
    <gl-alert v-if="errorLoadingVulnerabilities" :dismissible="false" variant="danger">
      {{
        s__(
          'Security Dashboard|Error fetching the vulnerability list. Please check your network connection and try again.',
        )
      }}
    </gl-alert>
    <vulnerability-list
      v-else
      :is-loading="isLoadingVulnerabilities"
      :vulnerabilities="vulnerabilities"
    >
      <template #emptyState>
        <gl-empty-state
          :title="s__(`No vulnerabilities found for this project`)"
          :svg-path="emptyStateSvgPath"
          :description="$options.emptyStateDecription"
          :primary-button-link="dashboardDocumentation"
          :primary-button-text="s__('Security Reports|Learn more about setting up your dashboard')"
        />
      </template>
    </vulnerability-list>
    <pagination-links
      v-if="pageInfo.total > 1"
      class="justify-content-center prepend-top-default"
      :page-info="pageInfo"
      :change="fetchPage"
    />
  </div>
</template>
