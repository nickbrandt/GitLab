<script>
import { mapActions } from 'vuex';
import { GlAlert, GlEmptyState, GlIcon, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'ThreatMonitoring',
  components: {
    GlAlert,
    GlEmptyState,
    GlIcon,
    GlLink,
  },
  props: {
    isWafSetup: {
      type: Boolean,
      required: true,
    },
    endpoint: {
      type: String,
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
    };
  },
  created() {
    if (this.isWafSetup) {
      this.setEndpoint(this.endpoint);
    }
  },
  methods: {
    ...mapActions('threatMonitoring', ['setEndpoint']),
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
    application. View the documentation for instructions on how to access the
    WAF logs to see what type of malicious traffic is trying to access your
    app.`,
  ),
};
</script>

<template>
  <gl-empty-state
    v-if="!isWafSetup"
    :title="s__('ThreatMonitoring|Web Application Firewall not enabled')"
    :description="$options.emptyStateDescription"
    :svg-path="emptyStateSvgPath"
    :primary-button-link="documentationPath"
    :primary-button-text="__('Learn more')"
  />

  <section v-else>
    <gl-alert
      v-if="showAlert"
      class="my-3"
      variant="tip"
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
          target="_blank"
          :href="documentationPath"
          :aria-label="s__('ThreatMonitoring|Threat Monitoring help page link')"
        >
          <gl-icon name="question" />
        </gl-link>
      </h2>
    </header>
  </section>
</template>
