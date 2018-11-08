<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { s__ } from '~/locale';
import { spriteIcon } from '~/lib/utils/common_utils';
import Tabs from '~/vue_shared/components/tabs/tabs';
import Tab from '~/vue_shared/components/tabs/tab.vue';
import IssueModal from 'ee/vue_shared/security_reports/components/modal.vue';
import SecurityDashboardTable from './security_dashboard_table.vue';
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
    VulnerabilityCountList,
  },
  props: {
    dashboardDocumentation: {
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
            title="${s__('Security Reports|Security Dashboard Documentation')}"
            href="${this.dashboardDocumentation}"
            target="_blank"
            rel="noopener
            noreferrer"
          >
            <span class="vertical-align-middle">${s__(
              'Security Reports|Security Dashboard Documentation',
            )}</span>
            ${spriteIcon('external-link', 's16 vertical-align-middle')}
          </a>
        `,
        html: true,
      };
    },
  },
  created() {
    this.setVulnerabilitiesEndpoint(this.vulnerabilitiesEndpoint);
    this.setVulnerabilitiesCountEndpoint(this.vulnerabilitiesCountEndpoint);
    this.fetchVulnerabilitiesCount();
  },
  methods: {
    ...mapActions('vulnerabilities', [
      'setVulnerabilitiesCountEndpoint',
      'setVulnerabilitiesEndpoint',
      'fetchVulnerabilitiesCount',
      'createIssue',
      'dismissVulnerability',
      'undoDismissal',
    ]),
  },
};
</script>

<template>
  <div>
    <vulnerability-count-list />
    <tabs stop-propagation>
      <tab active>
        <template slot="title">
          <span>{{ __('SAST') }}</span>
          <span
            v-if="sastCount"
            class="badge badge-pill"
          >
            {{ sastCount }}
          </span>
          <span
            v-popover="popoverOptions"
            class="text-muted prepend-left-4"
            :aria-label="__('help')"
          >
            <icon
              name="question"
              class="vertical-align-middle"
            />
          </span>
        </template>

        <security-dashboard-table />
      </tab>
    </tabs>
    <issue-modal
      :modal="modal"
      :can-create-issue-permission="true"
      :can-create-feedback-permission="true"
      @createNewIssue="createIssue({ vulnerability: modal.vulnerability })"
      @dismissIssue="dismissVulnerability({ vulnerability: modal.vulnerability })"
      @revertDismissIssue="undoDismissal({ vulnerability: modal.vulnerability })"
    />
  </div>
</template>
