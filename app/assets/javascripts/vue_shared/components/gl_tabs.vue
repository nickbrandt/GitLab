<script>
import { GlTabs } from '@gitlab/ui';

export default {
  components: {
    GlTabs,
  },
};
</script>

<template>
  <gl-tabs content-class="gl-display-none" v-bind="$attrs" justified v-on="$listeners">
    <slot></slot>
  </gl-tabs>
</template>
