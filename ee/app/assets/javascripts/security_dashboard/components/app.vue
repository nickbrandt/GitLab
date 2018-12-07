<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { s__ } from '~/locale';
import { spriteIcon } from '~/lib/utils/common_utils';
import Tabs from '~/vue_shared/components/tabs/tabs';
import Tab from '~/vue_shared/components/tabs/tab.vue';
import IssueModal from 'ee/vue_shared/security_reports/components/modal.vue';
import SecurityDashboardTable from './security_dashboard_table.vue';
import VulnerabilityChart from './vulnerability_chart.vue';
import VulnerabilityCountList from './vulnerability_count_list.vue';
import Icon from '~/vue_shared/components/icon.vue';
import popover from '~/vue_shared/directives/popover';

export default {
  name: 'SecurityDashboardApp',
  directives: {
    popover,
  },
  components: {
    Icon,
    IssueModal,
    SecurityDashboardTable,
    Tab,
    Tabs,
    VulnerabilityChart,
    VulnerabilityCountList,
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
    vulnerabilitiesEndpoint: {
      type: String,
      required: true,
    },
    vulnerabilitiesCountEndpoint: {
      type: String,
      required: true,
    },
    vulnerabilitiesHistoryEndpoint: {
      type: String,
      required: true,
    },
    vulnerabilityFeedbackHelpPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapGetters('vulnerabilities', ['vulnerabilitiesCountByReportType']),
    ...mapState('vulnerabilities', ['modal']),
    sastCount() {
      return this.vulnerabilitiesCountByReportType('sast');
    },
    popoverOptions() {
      return {
        trigger: 'click',
        placement: 'right',
        title: s__('Security Reports|At this time, the security dashboard only supports SAST.'),
        content: `
          <a
            title="${s__('Security Reports|Security dashboard documentation')}"
            href="${this.dashboardDocumentation}"
            target="_blank"
            rel="noopener
            noreferrer"
          >
            <span class="vertical-align-middle">${s__(
              'Security Reports|Security dashboard documentation',
            )}</span>
            ${spriteIcon('external-link', 's16 vertical-align-middle')}
          </a>
        `,
        html: true,
      };
    },
    chartFlagEnabled() {
      return gon.features && gon.features.groupSecurityDashboardHistory;
    },
  },
  created() {
    this.setVulnerabilitiesEndpoint(this.vulnerabilitiesEndpoint);
    this.setVulnerabilitiesCountEndpoint(this.vulnerabilitiesCountEndpoint);
    this.setVulnerabilitiesHistoryEndpoint(this.vulnerabilitiesHistoryEndpoint);
    this.fetchVulnerabilitiesCount();
  },
  methods: {
    ...mapActions('vulnerabilities', [
      'setVulnerabilitiesCountEndpoint',
      'setVulnerabilitiesHistoryEndpoint',
      'setVulnerabilitiesEndpoint',
      'fetchVulnerabilitiesCount',
      'createIssue',
      'dismissVulnerability',
      'revertDismissal',
    ]),
  },
};
</script>

<template>
  <div>
    <tabs stop-propagation>
      <tab active>
        <template slot="title">
          <span>{{ __('SAST') }}</span>
          <span v-if="sastCount" class="badge badge-pill"> {{ sastCount }} </span>
          <span
            v-popover="popoverOptions"
            class="text-muted prepend-left-4"
            :aria-label="__('help')"
          >
            <icon name="question" class="vertical-align-middle" />
          </span>
        </template>
        <vulnerability-count-list />
        <template v-if="chartFlagEnabled">
          <h4 class="my-4">{{ __('Vulnerability Chart') }}</h4>
          <vulnerability-chart />
        </template>
        <h4 class="my-4">{{ __('Vulnerability List') }}</h4>
        <security-dashboard-table
          :dashboard-documentation="dashboardDocumentation"
          :empty-state-svg-path="emptyStateSvgPath"
        />
      </tab>
    </tabs>
    <issue-modal
      :modal="modal"
      :vulnerability-feedback-help-path="vulnerabilityFeedbackHelpPath"
      :can-create-issue-permission="true"
      :can-create-feedback-permission="true"
      @createNewIssue="createIssue({ vulnerability: modal.vulnerability });"
      @dismissIssue="dismissVulnerability({ vulnerability: modal.vulnerability });"
      @revertDismissIssue="revertDismissal({ vulnerability: modal.vulnerability });"
    />
  </div>
</template>
