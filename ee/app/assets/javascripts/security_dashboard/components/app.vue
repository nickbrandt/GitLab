<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { s__ } from '~/locale';
import Tabs from '~/vue_shared/components/tabs/tabs';
import Tab from '~/vue_shared/components/tabs/tab.vue';
import SecurityDashboardTable from './security_dashboard_table.vue';
import VulnerabilityCountList from './vulnerability_count_list.vue';
import SvgBlankState from '~/pipelines/components/blank_state.vue';
import Icon from '~/vue_shared/components/icon.vue';
import popover from '~/vue_shared/directives/popover';

export default {
  name: 'SecurityDashboardApp',
  directives: {
    popover,
  },
  components: {
    Icon,
    SecurityDashboardTable,
    SvgBlankState,
    Tab,
    Tabs,
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
    errorStateSvgPath: {
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
    ...mapState('vulnerabilities', ['hasError']),
    sastCount() {
      return this.vulnerabilitiesCountByReportType('sast');
    },
    popoverOptions() {
      return {
        trigger: 'click',
        placement: 'right',
        title: s__(
          'Security Reports|At this time, the security dashboard only supports SAST. More analyzers are coming soon.',
        ),
        content: `
          <a
            title="${s__('Security Reports|Security Dashboard Roadmap')}"
            href="${this.dashboardDocumentation}"
            target="_blank"
            rel="noopener
            noreferrer"
          >
            <span class="vertical-align-middle">${s__(
              'Security Reports|Security Dashboard Roadmap',
            )}</span>
            ${gl.utils.spriteIcon('external-link', 's16 vertical-align-middle')}
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
    ]),
  },
};
</script>

<template>
  <div>
    <svg-blank-state
      v-if="hasError"
      :svg-path="errorStateSvgPath"
      :message="s__(`Security Reports|There was an error fetching the dashboard.
      Please try again in a few moments or contact your support team.`)"
    />
    <div v-else>
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
              class="text-muted ml-1"
            >
              <icon
                name="question"
                class="vertical-align-middle"
              />
            </span>
          </template>

          <security-dashboard-table
            :empty-state-svg-path="emptyStateSvgPath"
          />
        </tab>
      </tabs>
    </div>
  </div>
</template>
