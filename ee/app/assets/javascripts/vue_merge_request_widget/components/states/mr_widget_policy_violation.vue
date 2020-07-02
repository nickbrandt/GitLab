<script>
import statusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetPolicyViolation',
  components: {
    statusIcon,
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <div class="space-children">
      <status-icon status="warning" />
      <gl-button category="primary" variant="success" disabled="disabled" size="small">
        {{ s__('mrWidget|Merge') }}
      </gl-button>
    </div>
    <div class="media-body">
      <strong>
        {{ s__('mrWidget|You can only merge once the denied license is removed') }}
      </strong>
    </div>
  </div>
</template>
