<script>
import { GlLink, GlPopover } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'ApprovalCheckPopover',
  components: {
    GlLink,
    GlPopover,
    Icon,
  },
  props: {
    documentationLink: {
      type: String,
      required: false,
      default: '',
    },
    documentationText: {
      type: String,
      required: false,
      default: '',
    },
    title: {
      type: String,
      required: true,
    },
    text: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <span class="vertical-align-middle text-muted js-help">
    <icon
      ref="reportInfo"
      name="question"
      css-classes="text-info"
      :aria-label="__('help')"
      :size="14"
    />
    <gl-popover
      :target="() => $refs.reportInfo"
      placement="top"
      triggers="click blur"
      :title="title"
    >
      <div class="mb-2">{{ text }}</div>
      <gl-link v-if="documentationLink" target="_blank" :href="documentationLink">
        <span class="vertical-align-middle">{{ documentationText }}</span>
        <icon name="external-link" class="vertical-align-middle" />
      </gl-link>
    </gl-popover>
  </span>
</template>
