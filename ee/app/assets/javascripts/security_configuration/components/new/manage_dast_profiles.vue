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
};
</script>

<template>
  <gl-button :href="scanner.configuration_path" data-testid="manageButton">{{
    s__('SecurityConfiguration|Manage')
  }}</gl-button>
</template>
