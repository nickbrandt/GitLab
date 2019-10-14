<script>
import { GlTooltipDirective } from '@gitlab/ui';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import { __ } from '~/locale';
import timeagoMixin from '../../vue_shared/mixins/timeago';
import MemoryUsage from './memory_usage.vue';

export default {
  name: 'DeploymentInfo',
  components: {
    MemoryUsage,
    TooltipOnTruncate,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    computedDeploymentStatus: {
      type: String,
      required: true,
    },
    deployment: {
      type: Object,
      required: true,
    },
    showMetrics: {
      type: Boolean,
      required: true,
    },
  },
  deployedTextMap: {
    manual_deploy:  __('Can deploy manually to'),
    will_deploy: __('Will deploy to'),
    running: __('Deploying to'),
    success: __('Deployed to'),
    failed: __('Failed to deploy to'),
    canceled: __('Canceled deploy to'),
  },
  computed: {
    deployTimeago() {
      return this.timeFormated(this.deployment.deployed_at);
    },
    deployedText() {
      return this.$options.deployedTextMap[this.computedDeploymentStatus];
    },
    hasDeploymentTime() {
      return Boolean(this.deployment.deployed_at && this.deployment.deployed_at_formatted);
    },
    hasDeploymentMeta() {
      return Boolean(this.deployment.url && this.deployment.name);
    },
    hasMetrics() {
      return Boolean(this.deployment.metrics_url);
    },
    showMemoryUsage() {
      return this.hasMetrics && this.showMetrics;
    },
  },
};
</script>

<template>
  <div class="js-deployment-info deployment-info">
    <template v-if="hasDeploymentMeta">
      <span> {{ deployedText }} </span>
      <tooltip-on-truncate
        :title="deployment.name"
        truncate-target="child"
        class="deploy-link label-truncate"
      >
        <a
          :href="deployment.url"
          target="_blank"
          rel="noopener noreferrer nofollow"
          class="js-deploy-meta"
        >
          {{ deployment.name }}
        </a>
      </tooltip-on-truncate>
    </template>
    <span
      v-if="hasDeploymentTime"
      v-gl-tooltip
      :title="deployment.deployed_at_formatted"
      class="js-deploy-time"
    >
      {{ deployTimeago }}
    </span>
    <memory-usage
      v-if="showMemoryUsage"
      :metrics-url="deployment.metrics_url"
      :metrics-monitoring-url="deployment.metrics_monitoring_url"
    />
  </div>
</template>
