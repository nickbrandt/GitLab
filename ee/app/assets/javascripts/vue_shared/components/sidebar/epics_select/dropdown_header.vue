<script>
import { GlButton } from '@gitlab/ui';

import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlButton,
    Icon,
  },
};
</script>

<template>
  <div class="dropdown-title">
    <span>{{ __('Assign epic') }}</span>
    <gl-button
      :aria-label="__('Close')"
      variant="link"
      class="dropdown-title-button dropdown-menu-close"
    >
      <icon name="close" />
    </gl-button>
  </div>
</template>
