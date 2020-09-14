<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    path: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ideButtonTitle() {
      return this.disabled
        ? s__(
            'mrWidget|You are not allowed to edit this project directly. Please fork to make changes.',
          )
        : '';
    },
    href() {
      return this.disabled ? '#' : this.path;
    },
  },
};
</script>

<template>
  <span v-gl-tooltip :title="ideButtonTitle" :tabindex="disabled ? 0 : null">
    <gl-button
      :href="href"
      :disabled="disabled"
      class="js-web-ide"
      tabindex="0"
      role="button"
      data-qa-selector="open_in_web_ide_button"
    >
      <slot>{{ __('Web IDE') }}</slot>
    </gl-button>
  </span>
</template>
