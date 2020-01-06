<script>
import { mapActions, mapState } from 'vuex';
import { GlAlert, GlEmptyState, GlIcon, GlLink, GlPopover } from '@gitlab/ui';
import { s__ } from '~/locale';
import ThreatMonitoringFilters from './threat_monitoring_filters.vue';
import WafLoadingSkeleton from './waf_loading_skeleton.vue';
import WafStatisticsSummary from './waf_statistics_summary.vue';
import WafStatisticsHistory from './waf_statistics_history.vue';

export default {
  name: 'ThreatMonitoring',
  components: {
    GlAlert,
    GlEmptyState,
    GlIcon,
    GlLink,
    GlPopover,
    ThreatMonitoringFilters,
    WafLoadingSkeleton,
    WafStatisticsSummary,
    WafStatisticsHistory,
  },
  props: {
    defaultEnvironmentId: {
      type: Number,
      required: true,
    },
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    documentationPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      showAlert: true,

      // WAF requires the project to have at least one available environment.
      // An invalid default environment id means there there are no available
      // environments, therefore the WAF cannot be set up. A valid default
      // environment id only means that WAF *might* be set up.
      isWafMaybeSetUp: this.isValidEnvironmentId(this.defaultEnvironmentId),
    };
  },
  computed: {
    ...mapState('threatMonitoring', ['isLoadingWafStatistics']),
  },
  created() {
    if (this.isWafMaybeSetUp) {
      this.setCurrentEnvironmentId(this.defaultEnvironmentId);
      this.fetchEnvironments();
    }
  },
  methods: {
    ...mapActions('threatMonitoring', ['fetchEnvironments', 'setCurrentEnvironmentId']),
    isValidEnvironmentId(id) {
      return Number.isInteger(id) && id >= 0;
    },
    dismissAlert() {
      this.showAlert = false;
    },
  },
  emptyStateDescription: s__(
    `ThreatMonitoring|A Web Application Firewall (WAF) provides monitoring and
    rules to protect production applications. GitLab adds the modsecurity WAF
    plug-in when you install the Ingress app in your Kubernetes cluster.`,
  ),
  alertText: s__(
    `ThreatMonitoring|The graph below is an overview of traffic coming to your
    application as tracked by the Web Application Firewall (WAF). View the docs
    for instructions on how to access the WAF logs to see what type of
    malicious traffic is trying to access your app. The docs link is also
    accessible by clicking the "?" icon next to the title below.`,
  ),
  helpPopoverText: s__('ThreatMonitoring|At this time, threat monitoring only supports WAF data.'),
};
</script>

<template>
  <gl-empty-state
    v-if="!isWafMaybeSetUp"
    :title="s__('ThreatMonitoring|Web Application Firewall not enabled')"
    :description="$options.emptyStateDescription"
    :svg-path="emptyStateSvgPath"
    :primary-button-link="documentationPath"
    :primary-button-text="__('Learn More')"
  />

  <section v-else>
    <gl-alert
      v-if="showAlert"
      class="my-3"
      variant="info"
      :secondary-button-link="documentationPath"
      :secondary-button-text="__('View documentation')"
      @dismiss="dismissAlert"
    >
      {{ $options.alertText }}
    </gl-alert>
    <header class="my-3">
      <h2 class="h4 mb-1">
        {{ s__('ThreatMonitoring|Threat Monitoring') }}
        <gl-link
          ref="helpLink"
          target="_blank"
          :href="documentationPath"
          :aria-label="s__('ThreatMonitoring|Threat Monitoring help page link')"
        >
          <gl-icon name="question" />
        </gl-link>
        <gl-popover :target="() => $refs.helpLink" triggers="hover focus">
          {{ $options.helpPopoverText }}
        </gl-popover>
      </h2>
    </header>

    <threat-monitoring-filters />

    <waf-loading-skeleton v-if="isLoadingWafStatistics" class="mt-3" />

    <template v-else>
      <waf-statistics-summary class="mt-3" />
      <waf-statistics-history class="mt-3" />
    </template>
  </section>
</template>
