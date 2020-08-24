<script>
import { GlButton } from '@gitlab/ui';

export default {
  name: 'ResolveDiscussionButton',
  components: {
    GlButton,
  },
  props: {
    isResolving: {
      type: Boolean,
      required: false,
      default: false,
    },
    buttonTitle: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <gl-button
    data-testid="discussion-resolve-button"
    type="button"
    class="ml-sm-2"
    :loading="isResolving"
    @click="$emit('onClick')"
  >
    {{ buttonTitle }}
  </gl-button>
</template>
