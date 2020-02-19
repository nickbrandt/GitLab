<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlEmptyState, GlLoadingIcon, GlLink, GlIcon, GlTab, GlTabs, GlBadge } from '@gitlab/ui';
import { LICENSE_LIST } from '../store/constants';
import { LICENSE_MANAGEMENT } from 'ee/vue_shared/license_management/store/constants';
import PaginatedLicensesTable from './paginated_licenses_table.vue';
import PipelineInfo from './pipeline_info.vue';
import LicenseManagement from 'ee/vue_shared/license_management/license_management.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  name: 'ProjectLicensesApp',
  components: {
    GlEmptyState,
    GlLoadingIcon,
    GlLink,
    PaginatedLicensesTable,
    PipelineInfo,
    GlIcon,
    GlTab,
    GlTabs,
    GlBadge,
    LicenseManagement,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    documentationPath: {
      type: String,
      required: true,
    },
    readLicensePoliciesEndpoint: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      tabIndex: 0,
    };
  },
  computed: {
    ...mapState(LICENSE_LIST, ['initialized', 'licenses', 'reportInfo', 'listTypes']),
    ...mapState(LICENSE_MANAGEMENT, ['managedLicenses']),
    ...mapGetters(LICENSE_LIST, ['isJobSetUp', 'isJobFailed']),
    hasEmptyState() {
      return Boolean(!this.isJobSetUp || this.isJobFailed);
    },
    hasLicensePolicyList() {
      return Boolean(this.glFeatures.licensePolicyList);
    },
    licenseCount() {
      return this.licenses.length;
    },
    policyCount() {
      return this.managedLicenses.length;
    },
    isDetectedProjectTab() {
      return this.tabIndex === 0;
    },
  },
  created() {
    this.fetchLicenses();
  },
  methods: {
    ...mapActions(LICENSE_LIST, ['fetchLicenses']),
  },
};
</script>

<template>
  <gl-loading-icon v-if="!initialized" size="md" class="mt-4" />

  <gl-empty-state
    v-else-if="hasEmptyState"
    :title="s__('Licenses|View license details for your project')"
    :description="
      s__(
        'Licenses|The license list details information about the licenses used within your project.',
      )
    "
    :svg-path="emptyStateSvgPath"
    :primary-button-link="documentationPath"
    :primary-button-text="s__('Licenses|Learn more about license compliance')"
  />

  <div v-else>
    <h2 class="h4">
      {{ s__('Licenses|License Compliance') }}
      <gl-link :href="documentationPath" class="vertical-align-middle" target="_blank">
        <gl-icon name="question" />
      </gl-link>
    </h2>

    <pipeline-info
      v-if="isDetectedProjectTab"
      :path="reportInfo.jobPath"
      :timestamp="reportInfo.generatedAt"
    />
    <template v-else>{{ s__('Licenses|Specified policies in this project') }}</template>

    <!-- TODO: Remove feature flag -->
    <template v-if="hasLicensePolicyList">
      <gl-tabs v-model="tabIndex" content-class="pt-0">
        <gl-tab>
          <template #title>
            {{ s__('Licenses|Detected in Project') }}
            <gl-badge pill>{{ licenseCount }}</gl-badge>
          </template>

          <paginated-licenses-table />
        </gl-tab>

        <gl-tab>
          <template #title>
            {{ s__('Licenses|Policies') }}
            <gl-badge pill>{{ policyCount }}</gl-badge>
          </template>

          <license-management :api-url="readLicensePoliciesEndpoint" />
        </gl-tab>
      </gl-tabs>
    </template>

    <template v-else>
      <paginated-licenses-table class="mt-3" />
    </template>
  </div>
</template>
