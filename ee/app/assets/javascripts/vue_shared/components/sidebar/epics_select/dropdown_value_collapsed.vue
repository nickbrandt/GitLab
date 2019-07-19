<script>
import { GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    epic: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div
    v-gl-tooltip="{ boundary: 'viewport', placement: 'left' }"
    :title="epic.title"
    class="sidebar-collapsed-icon"
  >
    <icon name="epic" />
    <span class="collapse-truncated-title mt-1">{{ epic.title }}</span>
  </div>
</template>
