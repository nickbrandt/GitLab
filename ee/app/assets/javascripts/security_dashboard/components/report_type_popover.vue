<script>
import { GlPopover } from '@gitlab/ui';
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlPopover,
    Icon,
  },
  props: {
    dashboardDocumentation: {
      type: String,
      required: true,
    },
  },
  linkTitle: s__('Security Reports|Security dashboard documentation'),
};
</script>

<template>
  <span class="vertical-align-middle text-muted js-help">
    <icon id="reports-info" name="question" :aria-label="__('help')" />
    <gl-popover
      target="reports-info"
      placement="right"
      triggers="click"
      :title="
        s__(
          'Security Reports|At this time, the security dashboard only supports SAST and dependency scanning.',
        )
      "
    >
      <a
        v-if="dashboardDocumentation"
        target="_blank"
        rel="noopener noreferrer"
        :title="$options.linkTitle"
        :href="dashboardDocumentation"
      >
        <span class="vertical-align-middle">{{ $options.linkTitle }}</span>
        <icon name="external-link" :size="16" class="vertical-align-middle" />
      </a>
    </gl-popover>
  </span>
</template>
