<script>
import { GlTooltip } from '@gitlab/ui';
import icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'IssueCardWeight',
  components: {
    icon,
    GlTooltip,
  },
  props: {
    weight: {
      type: Number,
      required: true,
    },
    tagName: {
      type: String,
      required: false,
      default: 'a',
    },
  },
};
</script>

<template>
  <component
    :is="tagName"
    ref="itemWeight"
    class="board-card-info card-number board-card-weight"
    tabindex="1"
    v-on="$listeners"
  >
    <icon name="weight" css-classes="board-card-info-icon" />
    <span class="board-card-info-text"> {{ weight }} </span>
    <gl-tooltip
      :target="() => $refs.itemWeight"
      placement="bottom"
      container="body"
      class="js-item-weight"
      >{{ __('Weight') }}<br /><span class="text-tertiary">{{ weight }}</span>
    </gl-tooltip>
  </component>
</template>
