<script>
import { GlBanner } from '@gitlab/ui';
import Cookies from 'js-cookie';
import { parseBoolean } from '~/lib/utils/common_utils';
import axios from '~/lib/utils/axios_utils';
import ProjectVulnerabilitiesApp from './project_vulnerabilities.vue';
import ReportsNotConfigured from './empty_states/reports_not_configured.vue';
import SecurityDashboardLayout from './security_dashboard_layout.vue';
import VulnerabilitiesCountList from './vulnerability_count_list.vue';
import Filters from './first_class_vulnerability_filters.vue';
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
    securityDashboardHelpPath: {
      type: String,
      required: true,
    },
    projectFullPath: {
      type: String,
      required: false,
      default: '',
    },
    hasVulnerabilities: {
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
      required: false,
      default: '',
    },
    userCalloutsPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      filters: {},
      isBannerVisible: this.showIntroductionBanner && !parseBoolean(Cookies.get(BANNER_COOKIE_KEY)), // The and statement is for backward compatibility. See https://gitlab.com/gitlab-org/gitlab/-/issues/213671 for more information.
    };
  },
  inject: ['dashboardDocumentation'],
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
    <template v-if="hasVulnerabilities">
      <security-dashboard-layout>
        <template #header>
          <gl-banner
            v-if="isBannerVisible"
            class="mt-4"
            variant="introduction"
            :title="s__('SecurityReports|Introducing standalone vulnerabilities')"
            :button-text="s__('SecurityReports|Learn more')"
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
        </template>
        <template #sticky>
          <filters @filterChange="handleFilterChange" />
        </template>
        <project-vulnerabilities-app
          :dashboard-documentation="dashboardDocumentation"
          :project-full-path="projectFullPath"
          :filters="filters"
        />
      </security-dashboard-layout>
    </template>
    <reports-not-configured v-else :help-path="securityDashboardHelpPath" />
  </div>
</template>
