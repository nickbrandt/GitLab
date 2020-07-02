<script>
import { GlButton, GlFormInput, GlModal, GlModalDirective } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlFormInput,
    GlModal,
  },
  directives: {
    GlModalDirective,
  },
  props: {},
  computed: {},
  data() {
    return {
      name: '',
    };
  },
};
</script>
<template>
  <div>
    <gl-button
      v-gl-modal-directive="'create-value-stream-modal'"
      data-testid="create-value-stream"
      >{{ __('Create new value stream') }}</gl-button
    >
    <!-- no-fade: no idea 🤷‍♂️ -->
    <gl-modal
      modal-id="create-value-stream-modal"
      :title="__('Value stream name')"
      no-fade
      :action-primary="{ text: __('Create value stream') }"
      :action-cancel="{ text: __('Cancel') }"
      @primary="$emit('create')"
    >
      <gl-form-input id="name" :value="name" :placeholder="__('Example: My value stream')" />
    </gl-modal>
    <!-- :action-cancel -->
  </div>
</template>
