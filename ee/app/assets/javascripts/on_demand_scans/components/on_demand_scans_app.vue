<script>
import OnDemandScansFormOld from './on_demand_scans_form_old.vue';
import OnDemandScansForm from './on_demand_scans_form.vue';
import OnDemandScansEmptyState from './on_demand_scans_empty_state.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  name: 'OnDemandScansApp',
  components: {
    OnDemandScansFormOld,
    OnDemandScansForm,
    OnDemandScansEmptyState,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    helpPagePath: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    defaultBranch: {
      type: String,
      required: true,
    },
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    profilesLibraryPath: {
      type: String,
      required: true,
    },
    newSiteProfilePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      showForm: false,
    };
  },
};
</script>

<template>
  <div>
    <template v-if="showForm">
      <on-demand-scans-form
        v-if="glFeatures.securityOnDemandScansSiteProfilesFeatureFlag"
        :help-page-path="helpPagePath"
        :project-path="projectPath"
        :default-branch="defaultBranch"
        :profiles-library-path="profilesLibraryPath"
        :new-site-profile-path="newSiteProfilePath"
        @cancel="showForm = false"
      />
      <on-demand-scans-form-old
        v-else
        :help-page-path="helpPagePath"
        :project-path="projectPath"
        :default-branch="defaultBranch"
        @cancel="showForm = false"
      />
    </template>
    <on-demand-scans-empty-state
      v-else
      :help-page-path="helpPagePath"
      :empty-state-svg-path="emptyStateSvgPath"
      @createNewScan="showForm = true"
    />
  </div>
</template>
