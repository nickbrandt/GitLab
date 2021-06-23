<script>
import { GlLink } from '@gitlab/ui';

export default {
  components: {
    GlLink,
  },
  inject: ['commitBasePath'],
  props: {
    value: {
      type: String,
      required: true,
    },
  },
  computed: {
    commitPath() {
      return `${this.commitBasePath}/${this.value}`;
    },
  },
};
</script>

<template>
  <gl-link :href="commitPath">{{ value }}</gl-link>
</template>
