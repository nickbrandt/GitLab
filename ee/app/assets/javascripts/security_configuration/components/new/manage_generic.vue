<script>
import { GlButton } from '@gitlab/ui';

export default {
  components: {
    GlButton,
  },
  props: {
    scanner: {
      type: Object,
      required: true,
    },
  },
  computed: {
    canConfigure() {
      return Boolean(this.scanner.configuration_path && this.scanner.configured);
    },
    canEnable() {
      return Boolean(this.scanner.configuration_path && !this.scanner.configured);
    },
  },
};
</script>

<template>
  <gl-button v-if="canConfigure" :href="scanner.configuration_path" data-testid="configureButton">{{
    s__('SecurityConfiguration|Configure')
  }}</gl-button>

  <gl-button
    v-else-if="canEnable"
    variant="success"
    category="primary"
    :href="scanner.configuration_path"
    data-testid="enableButton"
    >{{ s__('SecurityConfiguration|Enable') }}</gl-button
  >
</template>
