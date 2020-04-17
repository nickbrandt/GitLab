<script>
  import {
    GlEmptyState,
    GlButton,
    GlLoadingIcon
  } from '@gitlab/ui';


  export default {
    components: {
      GlEmptyState,
      GlButton,
      GlLoadingIcon
    },
    props: {
      indexPath: {
        type: String,
        required: true,
      },
      enableSurfaceAlertsLink: {
        type: String,
        required: true,
      },
      surfaceAlertsEnabled: {
        type: Boolean,
        required: true,
      },
      illustrationPath: {
        type: String,
        required: true,
      },
    },
    data() {
      return {
        alerts: [],
      };
    },
    computed: {},
    methods: {},
  };
</script>

<template>
  <div>
    <div v-if="surfaceAlertsEnabled" class="surface-alerts-list">
      <div v-if="loading" class="py-3">
        <gl-loading-icon size="md" />
      </div>
    </div>
    <div v-else>
      <gl-empty-state :title="__('Surface alerts in GitLab')" :svg-path="illustrationPath">
        <template #description>
          <div>
            <span>{{ __('Display alerts from all your monitoring tools directly withing GitLab. Streamline the investigation of your alerts and the escalation of alerts to incidents.') }}</span>
            <a href="/help/user/project/operations/surface_alerts.html">
              {{ __('More information') }}
            </a>
            <gl-button category="primary" variant="success">{{ __('Authorize external service') }}</gl-button>
          </div>
        </template>
      </gl-empty-state>
    </div>
  </div>
</template>
