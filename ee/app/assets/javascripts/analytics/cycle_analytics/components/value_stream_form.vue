<script>
import { GlForm, GlFormInput, GlFormGroup, GlModal } from '@gitlab/ui';
import { debounce } from 'lodash';
import { mapState, mapActions } from 'vuex';
import { sprintf, __ } from '~/locale';
import { DATA_REFETCH_DELAY } from '../../shared/constants';

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
  name: 'ValueStreamForm',
  components: {
    GlForm,
    GlFormInput,
    GlFormGroup,
    GlModal,
  },
  props: {
    initialData: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      name: '',
      errors: {},
    };
  },
  computed: {
    ...mapState({
      initialFormErrors: 'createValueStreamErrors',
      isCreating: 'isCreatingValueStream',
    }),
    isValid() {
      return !this.errors.name?.length;
    },
    invalidFeedback() {
      return this.errors.name?.join('\n');
    },
    hasFormErrors() {
      const { initialFormErrors } = this;
      return Boolean(Object.keys(initialFormErrors).length);
    },
    isLoading() {
      return this.isCreating;
    },
  },
  watch: {
    initialFormErrors(newErrors = {}) {
      this.errors = newErrors;
    },
  },
  mounted() {
    const { initialFormErrors } = this;
    if (this.hasFormErrors) {
      this.errors = initialFormErrors;
    } else {
      this.onHandleInput();
    }
  },
  methods: {
    ...mapActions(['createValueStream']),
    onHandleInput: debounce(function debouncedValidation() {
      const { name } = this;
      this.errors = validate({ name });
    }, DATA_REFETCH_DELAY),
    onSubmit() {
      const { name } = this;
      return this.createValueStream({ name }).then(() => {
        if (!this.hasFormErrors) {
          this.$toast.show(sprintf(__("'%{name}' Value Stream created"), { name }), {
            position: 'top-center',
          });
          this.name = '';
        }
      });
    },
  },
};
</script>
<template>
  <gl-modal
    data-testid="create-value-stream-modal"
    modal-id="create-value-stream-modal"
    :title="__('Value Stream Name')"
    :action-primary="{
      text: __('Create Value Stream'),
      attributes: [
        { variant: 'success' },
        {
          disabled: !isValid,
        },
        { loading: isLoading },
      ],
    }"
    :action-cancel="{ text: __('Cancel') }"
    @primary.prevent="onSubmit"
  >
    <gl-form>
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
          :placeholder="__('Example: My Value Stream')"
          :state="isValid"
          required
          @input="onHandleInput"
        />
      </gl-form-group>
    </gl-form>
  </gl-modal>
</template>
