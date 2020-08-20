<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlButton,
  },
  props: {
    issuableId: {
      type: Number,
      required: true,
    },
    issuableType: {
      type: String,
      required: true,
    },
    isTodo: {
      type: Boolean,
      required: false,
      default: true,
    },
    isActionActive: {
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
  methods: {
    toggleTodo() {
      this.$emit('toggleTodo', {
        issuableType: this.issuableType,
        issuableId: this.issuableId,
      });
    },
  },
};
</script>

<template>
  <div>
    <slot :toggleTodo="toggleTodo" :label="buttonLabel">
      <gl-button :loading="isActionActive" :aria-label="buttonLabel" @click="toggleTodo">
        {{ buttonLabel }}
      </gl-button></slot
    >
  </div>
</template>
