<script>
import { GlDeprecatedButton, GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlDeprecatedButton,
    GlIcon,
  },
};
</script>

<template>
  <div class="dropdown-title">
    <span>{{ __('Assign epic') }}</span>
    <gl-deprecated-button
      :aria-label="__('Close')"
      variant="link"
      class="dropdown-title-button dropdown-menu-close"
    >
      <gl-icon name="close" />
    </gl-deprecated-button>
  </div>
</template>
