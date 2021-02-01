<script>
import { GlButton, GlDropdown, GlIcon } from '@gitlab/ui';

export default {
  name: 'GeoNodeActions',
  components: {
    GlButton,
    GlDropdown,
    GlIcon,
  },
  props: {
    primary: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      showActions: false,
    };
  },
};
</script>

<template>
  <div>
    <gl-dropdown
      class="gl-lg-display-none"
      toggle-class="gl-shadow-none! gl-bg-transparent! gl-p-3!"
      menu-class="gl-min-w-full! gl-w-auto! gl-px-5! gl-py-3!"
      right
    >
      <template #button-content>
        <gl-icon name="ellipsis_h" />
      </template>
      <div class="gl-display-flex gl-flex-direction-column gl-align-items-flex-end">
        <gl-button class="gl-mb-3">{{ __('Edit') }}</gl-button>
        <gl-button variant="danger" category="secondary" :disabled="primary">{{
          __('Remove')
        }}</gl-button>
      </div>
    </gl-dropdown>
    <div class="gl-display-none gl-lg-display-block">
      <gl-button class="gl-mr-3">{{ __('Edit') }}</gl-button>
      <gl-button variant="danger" category="secondary" :disabled="primary">{{
        __('Remove')
      }}</gl-button>
    </div>
  </div>
</template>
