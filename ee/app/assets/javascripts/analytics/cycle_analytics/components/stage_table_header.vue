<script>
import { GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'StageTableHeader',
  components: {
    Icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    headerClasses: {
      type: String,
      required: false,
      default: '',
    },
    title: {
      type: String,
      required: true,
    },
    tooltipTitle: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <li :class="headerClasses">
    <span class="stage-name align-middle font-weight-bold">{{ title }}</span>
    <icon
      v-gl-tooltip
      class="align-middle"
      :size="14"
      name="question"
      container=".stage-name"
      :title="tooltipTitle"
    />
  </li>
</template>
