<script>
import { GlButton, GlForm, GlFormInput, GlModal, GlModalDirective } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlForm,
    GlFormInput,
    GlModal,
  },
  directives: {
    GlModalDirective,
  },
  data() {
    return {
      name: '',
    };
  },
  computed: {
    isValid() {
      return Boolean(this.name.length);
    },
  },
};
</script>
<template>
  <gl-form>
    <gl-button v-gl-modal-directive="'create-value-stream-modal'">{{
      __('Create new value stream')
    }}</gl-button>
    <gl-modal
      modal-id="create-value-stream-modal"
      :title="__('Value Stream Name')"
      :action-primary="{
        text: __('Create value stream'),
        attributes: [
          { variant: 'primary' },
          {
            disabled: !isValid,
          },
        ],
      }"
      :action-cancel="{ text: __('Cancel') }"
      @primary="$emit('create', { name })"
    >
      <gl-form-input id="name" v-model="name" :placeholder="__('Example: My value stream')" />
    </gl-modal>
  </gl-form>
</template>
