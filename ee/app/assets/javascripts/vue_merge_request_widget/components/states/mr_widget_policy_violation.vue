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
      <button type="button" class="btn btn-success btn-sm" disabled="true">
        {{ s__('mrWidget|Merge') }}
      </button>
    </div>
    <div class="media-body">
      <span class="bold">
        {{ s__('mrWidget|You can only merge once the denied license is removed') }}
      </span>
    </div>
  </div>
</template>
