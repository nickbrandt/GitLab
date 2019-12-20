<script>
import { GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import _ from 'underscore';

export default {
  name: 'DeleteButton',
  components: {
    GlButton,
    GlModal,
  },
  directives: {
    GlModalDirective,
  },
  props: {
    isDeleting: {
      type: Boolean,
      required: false,
      default: false,
    },
    buttonClass: {
      type: String,
      required: false,
      default: '',
    },
    buttonVariant: {
      type: String,
      required: false,
      default: '',
    },
    hasSelectedDesigns: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      modalId: _.uniqueId('design-deletion-confirmation-'),
    };
  },
};
</script>

<template>
  <div>
    <gl-modal
      :modal-id="modalId"
      :title="s__('DesignManagement|Delete designs confirmation')"
      :ok-title="s__('DesignManagement|Delete')"
      ok-variant="danger"
      @ok="$emit('deleteSelectedDesigns')"
    >
      <p>{{ s__('DesignManagement|Are you sure you want to delete the selected designs?') }}</p>
    </gl-modal>
    <gl-button
      v-gl-modal-directive="modalId"
      :variant="buttonVariant"
      :disabled="isDeleting || !hasSelectedDesigns"
      :class="buttonClass"
    >
      <slot></slot>
    </gl-button>
  </div>
</template>
