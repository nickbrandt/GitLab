<script>
import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import tooltip from '~/vue_shared/directives/tooltip';
import TodoButton from '~/vue_shared/components/todo_button.vue';

export default {
  directives: {
    tooltip,
  },
  components: {
    GlIcon,
    GlLoadingIcon,
    TodoButton,
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
    collapsed: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    collapsedButtonIconClasses() {
      return this.isTodo ? 'todo-undone' : '';
    },
    collapsedButtonIcon() {
      return this.isTodo ? 'todo-done' : 'todo-add';
    },
  },
};
</script>

<template>
  <todo-button
    #default="{ toggleTodo, label }"
    :class="!collapsed ? 'float-right' : ''"
    :issuable-type="issuableType"
    :issuable-id="issuableId"
    :is-todo="isTodo"
    :is-action-active="isActionActive"
    @toggleTodo="$emit('toggleTodo', $event)"
    ><button
      v-if="collapsed"
      v-tooltip
      class="btn-blank sidebar-collapsed-icon"
      type="button"
      role="button"
      :title="label"
      :aria-label="label"
      data-placement="left"
      data-container="body"
      data-boundary="viewport"
      @click="toggleTodo"
    >
      <gl-icon
        v-show="!isActionActive"
        :class="collapsedButtonIconClasses"
        :name="collapsedButtonIcon"
      />
      <gl-loading-icon v-show="isActionActive" :inline="true" /></button
  ></todo-button>
</template>
