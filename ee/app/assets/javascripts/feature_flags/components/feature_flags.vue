<script>
import { GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import FeatureFlagsTable from './feature_flags_table.vue';
import store from '../store';
import { __ } from '~/locale';
import NavigationTabs from '~/vue_shared/components/navigation_tabs.vue';
import TablePagination from '~/vue_shared/components/table_pagination.vue';
import {
  getParameterByName,
  historyPushState,
  buildUrlWithCurrentLocation,
} from '~/lib/utils/common_utils';

export default {
  store,
  components: {
    FeatureFlagsTable,
    NavigationTabs,
    TablePagination,
    GlEmptyState,
    GlLoadingIcon,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    csrfToken: {
      type: String,
      required: true,
    },
    errorStateSvgPath: {
      type: String,
      required: true,
    },
    featureFlagsHelpPagePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      scope: getParameterByName('scope') || this.$options.scopes.all,
      page: getParameterByName('page') || '1',
    };
  },
  scopes: {
    all: 'all',
    enabled: 'enabled',
    disabled: 'disabled',
  },
  computed: {
    ...mapState(['featureFlags', 'count', 'pageInfo', 'isLoading', 'hasError', 'options']),
    shouldRenderTabs() {
      /* Do not show tabs until after the first request to get the count */
      return this.count.all !== undefined;
    },
    shouldRenderPagination() {
      return (
        !this.isLoading &&
        !this.hasError &&
        this.featureFlags.length &&
        this.pageInfo.total > this.pageInfo.perPage
      );
    },
    shouldShowEmptyState() {
      return !this.isLoading && !this.hasError && this.featureFlags.length === 0;
    },
    shouldRenderTable() {
      return !this.isLoading && this.featureFlags.length > 0 && !this.hasError;
    },
    shouldRenderErrorState() {
      return this.hasError && !this.isLoading;
    },
    tabs() {
      const { scopes } = this.$options;

      return [
        {
          name: __('All'),
          scope: scopes.all,
          count: this.count.all,
          isActive: this.scope === scopes.all,
        },
        {
          name: __('Enabled'),
          scope: scopes.enabled,
          count: this.count.enabled,
          isActive: this.scope === scopes.enabled,
        },
        {
          name: __('Disabled'),
          scope: scopes.disabled,
          count: this.count.disabled,
          isActive: this.scope === scopes.disabled,
        },
      ];
    },
  },
  created() {
    this.setFeatureFlagsEndpoint(this.endpoint);
    this.setFeatureFlagsOptions({ scope: this.scope, page: this.page });
    this.fetchFeatureFlags();
  },
  methods: {
    ...mapActions(['setFeatureFlagsEndpoint', 'setFeatureFlagsOptions', 'fetchFeatureFlags']),
    onChangeTab(scope) {
      this.scope = scope;
      this.updateFeatureFlagOptions({
        scope,
        page: '1',
      });
    },
    onChangePage(page) {
      this.updateFeatureFlagOptions({
        scope: this.scope,
        /* URLS parameters are strings, we need to parse to match types */
        page: Number(page).toString(),
      });
    },
    updateFeatureFlagOptions(parameters) {
      const queryString = Object.keys(parameters)
        .map(parameter => {
          const value = parameters[parameter];
          return `${parameter}=${encodeURIComponent(value)}`;
        })
        .join('&');

      historyPushState(buildUrlWithCurrentLocation(`?${queryString}`));
      this.setFeatureFlagsOptions(parameters);
      this.fetchFeatureFlags();
    },
  },
};
</script>
<template>
  <div>
    <div v-if="shouldRenderTabs" class="top-area scrolling-tabs-container inner-page-scroll-tabs">
      <navigation-tabs :tabs="tabs" scope="featureflags" @onChangeTab="onChangeTab" />
    </div>

    <gl-loading-icon
      v-if="isLoading"
      :label="s__('Pipelines|Loading Pipelines')"
      :size="3"
      class="prepend-top-20"
    />

    <template v-else-if="shouldRenderErrorState">
      <gl-empty-state
        :title="s__(`FeatureFlags|There was an error fetching the feature flags.`)"
        :description="s__(`FeatureFlags|Try again in a few moments or contact your support team.`)"
        :svg-path="errorStateSvgPath"
      />
    </template>

    <template v-else-if="shouldShowEmptyState">
      <gl-empty-state
        class="js-feature-flags-empty-state"
        :title="s__(`FeatureFlags|Get started with feature flags`)"
        :description="
          s__(
            `FeatureFlags|Feature flags allow you to configure your code into different flavors by dynamically toggling certain functionality.`,
          )
        "
        :svg-path="errorStateSvgPath"
        :primary-button-link="featureFlagsHelpPagePath"
        :primary-button-text="s__(`FeatureFlags|More Information`)"
      />
    </template>

    <template v-else-if="shouldRenderTable">
      <feature-flags-table :csrf-token="csrfToken" :feature-flags="featureFlags" />
    </template>

    <table-pagination v-if="shouldRenderPagination" :change="onChangePage" :page-info="pageInfo" />
  </div>
</template>
