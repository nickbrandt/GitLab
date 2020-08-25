<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlButton,
  },
  props: {
    isTodo: {
      type: Boolean,
      required: false,
      default: true,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    buttonLabel() {
      return this.isTodo ? __('Mark as done') : __('Add a To-Do');
    },
  },
};
</script>

<template>
  <gl-button :loading="loading" :aria-label="buttonLabel" @click="$emit('click', $event)">
    {{ buttonLabel }}
  </gl-button>
</template>
