<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlEmptyState, GlLoadingIcon, GlLink, GlIcon } from '@gitlab/ui';
import { LICENSE_LIST } from '../store/constants';
import PaginatedLicensesTable from './paginated_licenses_table.vue';
import PipelineInfo from './pipeline_info.vue';

export default {
  name: 'ProjectLicensesApp',
  components: {
    GlEmptyState,
    GlLoadingIcon,
    GlLink,
    PaginatedLicensesTable,
    PipelineInfo,
    GlIcon,
  },
  props: {
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    documentationPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(LICENSE_LIST, ['initialized', 'reportInfo']),
    ...mapGetters(LICENSE_LIST, ['isJobSetUp', 'isJobFailed']),
    hasEmptyState() {
      return Boolean(!this.isJobSetUp || this.isJobFailed);
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

    <pipeline-info :path="reportInfo.jobPath" :timestamp="reportInfo.generatedAt" />
    <paginated-licenses-table class="mt-3" />
  </div>
</template>
