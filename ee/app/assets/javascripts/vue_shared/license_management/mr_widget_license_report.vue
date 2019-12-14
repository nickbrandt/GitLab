<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { GlLink } from '@gitlab/ui';
import reportsMixin from 'ee/vue_shared/security_reports/mixins/reports_mixin';
import SetLicenseApprovalModal from 'ee/vue_shared/license_management/components/set_approval_status_modal.vue';
import { componentNames } from 'ee/reports/components/issue_body';
import Icon from '~/vue_shared/components/icon.vue';
import ReportSection from '~/reports/components/report_section.vue';

import createStore from './store';

const store = createStore();

export default {
  name: 'MrWidgetLicenses',
  componentNames,
  store,
  components: {
    GlLink,
    ReportSection,
    SetLicenseApprovalModal,
    Icon,
  },
  mixins: [reportsMixin],
  props: {
    headPath: {
      type: String,
      required: true,
    },
    basePath: {
      type: String,
      required: false,
      default: null,
    },
    fullReportPath: {
      type: String,
      required: false,
      default: null,
    },
    licenseManagementSettingsPath: {
      type: String,
      required: false,
      default: null,
    },
    apiUrl: {
      type: String,
      required: true,
    },
    licensesApiPath: {
      type: String,
      required: false,
      default: '',
    },
    canManageLicenses: {
      type: Boolean,
      required: true,
    },
    reportSectionClass: {
      type: String,
      required: false,
      default: '',
    },
    alwaysOpen: {
      type: Boolean,
      required: false,
      default: false,
    },
    securityApprovalsHelpPagePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapState(['loadLicenseReportError']),
    ...mapGetters([
      'licenseReport',
      'isLoading',
      'licenseSummaryText',
      'reportContainsBlacklistedLicense',
    ]),
    hasLicenseReportIssues() {
      const { licenseReport } = this;
      return licenseReport && licenseReport.length > 0;
    },
    licenseReportStatus() {
      return this.checkReportStatus(this.isLoading, this.loadLicenseReportError);
    },
    showActionButtons() {
      return this.licenseManagementSettingsPath !== null || this.fullReportPath !== null;
    },
  },
  watch: {
    licenseReport() {
      this.$emit('updateBadgeCount', this.licenseReport.length);
    },
  },
  mounted() {
    const { headPath, basePath, apiUrl, canManageLicenses, licensesApiPath } = this;

    this.setAPISettings({
      apiUrlManageLicenses: apiUrl,
      headPath,
      basePath,
      canManageLicenses,
      licensesApiPath,
    });

    if (gon.features && gon.features.parsedLicenseReport) {
      this.loadParsedLicenseReport();
    } else {
      this.loadLicenseReport();
      this.loadManagedLicenses();
    }
  },
  methods: {
    ...mapActions([
      'setAPISettings',
      'loadManagedLicenses',
      'loadLicenseReport',
      'loadParsedLicenseReport',
    ]),
  },
};
</script>
<template>
  <div>
    <set-license-approval-modal />
    <report-section
      :status="licenseReportStatus"
      :loading-text="licenseSummaryText"
      :error-text="licenseSummaryText"
      :neutral-issues="licenseReport"
      :has-issues="hasLicenseReportIssues"
      :component="$options.componentNames.LicenseIssueBody"
      :class="reportSectionClass"
      :always-open="alwaysOpen"
      class="license-report-widget mr-report"
      data-qa-selector="license_report_widget"
    >
      <template #success>
        {{ licenseSummaryText }}
        <gl-link
          v-if="reportContainsBlacklistedLicense && securityApprovalsHelpPagePath"
          :href="securityApprovalsHelpPagePath"
          class="js-security-approval-help-link"
          target="_blank"
        >
          <icon :size="12" name="question" />
        </gl-link>
      </template>
      <div v-if="showActionButtons" slot="actionButtons" class="append-right-default">
        <a
          v-if="licenseManagementSettingsPath"
          :class="{ 'append-right-8': fullReportPath }"
          :href="licenseManagementSettingsPath"
          class="btn btn-default btn-sm js-manage-licenses"
        >
          {{ s__('ciReport|Manage licenses') }}
        </a>
        <a
          v-if="fullReportPath"
          :href="fullReportPath"
          target="_blank"
          class="btn btn-default btn-sm js-full-report"
        >
          {{ s__('ciReport|View full report') }} <icon :size="16" name="external-link" />
        </a>
      </div>
    </report-section>
  </div>
</template>
