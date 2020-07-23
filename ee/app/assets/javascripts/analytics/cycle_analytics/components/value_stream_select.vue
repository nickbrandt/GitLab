<script>
import {
  GlButton,
  GlNewDropdown as GlDropdown,
  GlNewDropdownItem as GlDropdownItem,
  GlNewDropdownDivider as GlDropdownDivider,
  GlForm,
  GlFormInput,
  GlFormGroup,
  GlModal,
  GlModalDirective,
} from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { sprintf, __ } from '~/locale';
import { debounce } from 'lodash';
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
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
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
      data: 'valueStreams',
      selectedValueStream: 'selectedValueStream',
    }),
    isValid() {
      return !this.errors?.name.length;
    },
    invalidFeedback() {
      return this.errors?.name.join('\n');
    },
    hasValueStreams() {
      return Boolean(this.data.length);
    },
    selectedValueStreamName() {
      return this.selectedValueStream?.name || '';
    },
    selectedValueStreamId() {
      return this.selectedValueStream?.id || null;
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
    ...mapActions(['createValueStream', 'setSelectedValueStream']),
    onSubmit() {
      const { name } = this;
      return this.createValueStream({ name }).then(() => {
        this.$toast.show(sprintf(__("'%{name}' Value Stream created"), { name }), {
          position: 'top-center',
        });
        this.name = '';
      });
    },
    onHandleInput: debounce(function debouncedValidation() {
      const { name } = this;
      this.errors = validate({ name });
    }, DATA_REFETCH_DELAY),
    isSelected(id) {
      return Boolean(this.selectedValueStreamId && this.selectedValueStreamId === id);
    },
    onSelect(id) {
      this.setSelectedValueStream(id);
    },
  },
};
</script>
<template>
  <gl-form>
    <gl-dropdown v-if="hasValueStreams" :text="selectedValueStreamName" right>
      <gl-dropdown-item
        v-for="{ id, name: streamName } in data"
        :key="id"
        :is-check-item="true"
        :is-checked="isSelected(id)"
        @click="onSelect(id)"
        >{{ streamName }}</gl-dropdown-item
      >
      <gl-dropdown-divider />
      <gl-dropdown-item v-gl-modal-directive="'create-value-stream-modal'" @click="onHandleInput">{{
        __('Create new Value Stream')
      }}</gl-dropdown-item>
    </gl-dropdown>
    <gl-button v-else v-gl-modal-directive="'create-value-stream-modal'" @click="onHandleInput">{{
      __('Create new Value Stream')
    }}</gl-button>
    <gl-modal
      ref="modal"
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
    </gl-modal>
  </gl-form>
</template>
