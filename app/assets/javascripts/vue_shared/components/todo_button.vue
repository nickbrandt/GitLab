<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

const MARK_TEXT = __('Mark as done');
const TODO_TEXT = __('Add a To-Do');

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
      return this.isTodo ? MARK_TEXT : TODO_TEXT;
    },

    buttonIcon() {
      return this.isTodo ? 'todo-done' : 'todo-add';
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
