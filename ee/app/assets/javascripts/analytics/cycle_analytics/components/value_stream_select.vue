<script>
import { GlButton, GlForm, GlFormInput, GlFormGroup, GlModal, GlModalDirective } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { sprintf, __ } from '~/locale';
import { debounce } from 'lodash';

const ERRORS = {
  MIN_LENGTH: __('Name is required'),
  MAX_LENGTH: __('Maximum length 100 characters'),
};

const validate = ({ name }) => {
  const errors = { name: [] };
  if (name.length > 100) {
    errors.name.push(ERRORS.MAX_LENGTH);
  }
  if (!name.length) {
    errors.name.push(ERRORS.MIN_LENGTH);
  }
  return errors;
};

export default {
  components: {
    GlButton,
    GlForm,
    GlFormInput,
    GlFormGroup,
    GlModal,
  },
  directives: {
    GlModalDirective,
  },
  data() {
    return {
      name: '',
      errors: { name: [] },
    };
  },
  computed: {
    ...mapState({
      isLoading: 'isCreatingValueStream',
      initialFormErrors: 'createValueStreamErrors',
    }),
    isValid() {
      return !this.errors?.name.length;
    },
    invalidFeedback() {
      return this.errors?.name.join('\n');
    },
  },
  mounted() {
    const { initialFormErrors } = this;
    if (Object.keys(initialFormErrors).length) {
      this.errors = initialFormErrors;
    } else {
      this.onHandleInput();
    }
  },
  methods: {
    ...mapActions(['createValueStream']),
    onSubmit() {
      const { name } = this;
      return this.createValueStream({ name }).then(() => {
        this.$refs.modal.hide();
        this.$toast.show(sprintf(__("'%{name}' Value Stream created"), { name }), {
          position: 'top-center',
        });
        this.name = '';
      });
    },
    onHandleInput: debounce(function debouncedValidation() {
      const { name } = this;
      this.errors = validate({ name });
    }, 250),
  },
};
</script>
<template>
  <gl-form>
    <gl-button v-gl-modal-directive="'create-value-stream-modal'" @click="onHandleInput">{{
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
      <gl-form-group
        :label="__('Name')"
        label-for="create-value-stream-name"
        :invalid-feedback="invalidFeedback"
        :state="isValid"
      >
        <gl-form-input
          id="create-value-stream-name"
          v-model.trim="name"
          name="create-value-stream-name"
          :placeholder="__('Example: My value stream')"
          :state="isValid"
          required
          @input="onHandleInput"
        />
      </gl-form-group>
    </gl-modal>
  </gl-form>
</template>
