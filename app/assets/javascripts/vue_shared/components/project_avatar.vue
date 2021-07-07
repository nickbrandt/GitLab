<script>
import { GlAvatar } from '@gitlab/ui';

export default {
  components: {
    GlAvatar,
  },
  props: {
    projectName: {
      type: String,
      required: true,
    },
    projectAvatarUrl: {
      type: String,
      required: false,
      default: undefined,
    },
    size: {
      type: Number,
      default: 32,
      required: false,
    },
  },
};
</script>

<template>
  <gl-avatar
    shape="rect"
    :entity-name="projectName"
    :src="projectAvatarUrl"
    :alt="projectName"
    :size="size"
  />
</template>
