<script>
import { GlButton, GlForm, GlFormInput, GlModal, GlModalDirective } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { sprintf, __ } from '~/locale';

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
  props: {
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      name: '',
    };
  },
  computed: {
    ...mapState({ isCreatingValueStream: 'isLoading' }),
    isValid() {
      return Boolean(this.name.length);
    },
  },
  methods: {
    ...mapActions(['createValueStream']),
    onSubmit() {
      const { name } = this;
      return this.createValueStream({ name }).then(() => {
        this.$refs.modal.hide();
        this.$toast.show(sprintf(__("'%{name}' Value Stream created"), { name }));
        this.name = '';
      });
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
      ref="modal"
      modal-id="create-value-stream-modal"
      :title="__('Value Stream Name')"
      :action-primary="{
        text: __('Create value stream'),
        attributes: [
          { variant: 'primary' },
          {
            disabled: !isValid,
          },
          { loading: isLoading },
        ],
      }"
      :action-cancel="{ text: __('Cancel') }"
      @primary.prevent="onSubmit"
    >
      <gl-form-input id="name" v-model="name" :placeholder="__('Example: My value stream')" />
    </gl-modal>
  </gl-form>
</template>
