<script>
import { GlEmptyState, GlButton, GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    GlEmptyState,
    GlButton,
    GlLoadingIcon,
  },
  props: {
    indexPath: {
      type: String,
      required: true,
    },
    enableSurfaceAlertsPath: {
      type: String,
      required: true,
    },
      emptyAlertSvgPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      alerts: [],
      loading: false,
    };
  },
  computed: {},
  methods: {},
};
</script>

<template>
  <div>
    <div v-if="alerts.length > 0" class="surface-alerts-list">
      <div v-if="loading" class="py-3">
        <gl-loading-icon size="md" />
      </div>
    </div>
    <div v-else>
      <gl-empty-state :title="__('Surface alerts in GitLab')" :svg-path="emptyAlertSvgPath">
        <template #description>
          <div class="d-block">
            <span>{{
              __(
                'Display alerts from all your monitoring tools directly within GitLab. Streamline the investigation of your alerts and the escalation of alerts to incidents.',
              )
            }}</span>
            <a href="/help/user/project/operations/surface_alerts.html">
              {{ __('More information') }}
            </a>
          </div>
          <div class="d-block center pt-4">
            <gl-button category="primary" variant="success" :href="enableSurfaceAlertsPath">{{
              __('Authorize external service')
            }}</gl-button>
          </div>
        </template>
      </gl-empty-state>
    </div>
  </div>
</template>
