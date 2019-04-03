<script>
import { GlTooltipDirective, GlButton } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlButton,
    Icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
};
</script>

<template>
  <div class="d-flex align-items-center">
    <div class="square s24 d-flex-center mr-2 text-tertiary">
      <icon name="folder-o" :size="16" />
    </div>
    <span>{{ __('Private group(s)') }}</span>
    <gl-button
      v-gl-tooltip
      :title="__('One or more groups that you don\'t have access to.')"
      variant="blank"
      class="ml-1 text-secondary"
    >
      <icon name="question-o" :size="16" />
    </gl-button>
  </div>
</template>
