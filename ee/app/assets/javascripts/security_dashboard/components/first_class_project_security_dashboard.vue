<script>
import { GlBanner } from '@gitlab/ui';
import Cookies from 'js-cookie';
import { parseBoolean } from '~/lib/utils/common_utils';
import axios from '~/lib/utils/axios_utils';
import ProjectVulnerabilitiesApp from 'ee/vulnerabilities/components/project_vulnerabilities_app.vue';
import ReportsNotConfigured from 'ee/security_dashboard/components/empty_states/reports_not_configured.vue';
import SecurityDashboardLayout from 'ee/security_dashboard/components/security_dashboard_layout.vue';
import VulnerabilitiesCountList from 'ee/security_dashboard/components/vulnerability_count_list.vue';
import Filters from 'ee/security_dashboard/components/first_class_vulnerability_filters.vue';
import CsvExportButton from './csv_export_button.vue';

export const BANNER_COOKIE_KEY = 'hide_vulnerabilities_introduction_banner';

export default {
  components: {
    ProjectVulnerabilitiesApp,
    ReportsNotConfigured,
    SecurityDashboardLayout,
    VulnerabilitiesCountList,
    CsvExportButton,
    Filters,
    GlBanner,
  },
  props: {
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    securityDashboardHelpPath: {
      type: String,
      required: true,
    },
    projectFullPath: {
      type: String,
      required: false,
      default: '',
    },
    dashboardDocumentation: {
      type: String,
      required: false,
      default: '',
    },
    hasPipelineData: {
      type: Boolean,
      required: false,
      default: false,
    },
    vulnerabilitiesExportEndpoint: {
      type: String,
      required: false,
      default: '',
    },
    showIntroductionBanner: {
      type: Boolean,
      required: true,
    },
    userCalloutId: {
      type: String,
      required: true,
    },
    userCalloutsPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      filters: {},
      isBannerVisible: this.showIntroductionBanner && !parseBoolean(Cookies.get(BANNER_COOKIE_KEY)), // The and statement is for backward compatibility. See https://gitlab.com/gitlab-org/gitlab/-/issues/213671 for more information.
    };
  },
  methods: {
    handleFilterChange(filters) {
      this.filters = filters;
    },
    handleBannerClose() {
      this.isBannerVisible = false;

      axios.post(this.userCalloutsPath, {
        feature_name: this.userCalloutId,
      });
    },
  },
};
</script>

<template>
  <div>
    <template v-if="hasPipelineData">
      <security-dashboard-layout>
        <template #header>
          <gl-banner
            v-if="isBannerVisible"
            class="mt-4"
            variant="introduction"
            :title="s__('SecurityReports|Introducing standalone vulnerabilities')"
            :button-text="s__('SecurityReports|Learn More')"
            :button-link="dashboardDocumentation"
            @close="handleBannerClose"
          >
            <div class="mb-2">
              {{
                s__(
                  'SecurityReports|Each vulnerability now has a unique page that can be directly linked to, shared, referenced, and tracked as the single source of truth. Vulnerability occurrences also persist across scanner runs, which improves tracking and visibility and reduces duplicates between scans.',
                )
              }}
            </div>
          </gl-banner>
          <div class="mt-4 d-flex">
            <h4 class="flex-grow mt-0 mb-0">{{ __('Vulnerabilities') }}</h4>
            <csv-export-button :vulnerabilities-export-endpoint="vulnerabilitiesExportEndpoint" />
          </div>
          <vulnerabilities-count-list :project-full-path="projectFullPath" />
          <filters @filterChange="handleFilterChange" />
        </template>
        <project-vulnerabilities-app
          :dashboard-documentation="dashboardDocumentation"
          :empty-state-svg-path="emptyStateSvgPath"
          :project-full-path="projectFullPath"
          :filters="filters"
        />
      </security-dashboard-layout>
    </template>
    <reports-not-configured
      v-else
      :svg-path="emptyStateSvgPath"
      :help-path="securityDashboardHelpPath"
    />
  </div>
</template>
