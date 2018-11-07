<script>
import { GlTooltipDirective } from '@gitlab-org/gitlab-ui';
import icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'IssueCardWeight',
  components: {
    icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    weight: {
      type: Number,
      required: true,
    },
  },
};
</script>

<template>
  <a
    v-gl-tooltip
    :title="__('Weight')"
    class="board-card-info card-number board-card-weight"
    data-container="body"
    data-placement="bottom"
    tabindex="1"
    v-on="$listeners"
  >
    <icon
      name="scale"
      css-classes="board-card-info-icon"
    /><span class="board-card-info-text">{{ weight }}</span>
  </a>
</template>
