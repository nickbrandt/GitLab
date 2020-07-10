<script>
import { GlButton } from '@gitlab/ui';
import StatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetPolicyViolation',
  components: {
    GlButton,
    StatusIcon,
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <div class="space-children d-flex">
      <status-icon status="warning" />
      <gl-button category="primary" variant="success" disabled size="small">
        {{ s__('mrWidget|Merge') }}
      </gl-button>
    </div>
    <div class="media-body">
      <strong class="bold">
        {{ s__('mrWidget|You can only merge once the denied license is removed') }}
      </strong>
    </div>
  </div>
</template>
