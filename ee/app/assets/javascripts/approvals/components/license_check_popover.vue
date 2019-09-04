<script>
import { GlLink, GlPopover } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'LicenseCheckPopover',
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
  },
};
</script>

<template>
  <span class="vertical-align-middle text-muted js-help">
    <icon id="reports-info" name="question" :aria-label="__('help')" :size="14" />
    <gl-popover
      target="reports-info"
      placement="top"
      triggers="click"
      :title="
        __(
          'License-Check requires merge request approval for newly detected licenses that are blacklisted.',
        )
      "
    >
      <gl-link v-if="documentationLink" target="_blank" :href="documentationLink">
        <span class="vertical-align-middle">{{ __('Learn more about license check') }}</span>
        <icon name="external-link" class="vertical-align-middle" />
      </gl-link>
    </gl-popover>
  </span>
</template>
