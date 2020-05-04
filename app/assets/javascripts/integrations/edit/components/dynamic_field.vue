<script>
import { startCase, isEmpty } from 'lodash';
import { __, sprintf } from '~/locale';
import { GlFormGroup, GlFormCheckbox, GlFormInput, GlFormSelect, GlFormTextarea } from '@gitlab/ui';

export default {
  name: 'DynamicField',
  components: {
    GlFormGroup,
    GlFormCheckbox,
    GlFormInput,
    GlFormSelect,
    GlFormTextarea,
  },
  props: {
    choices: {
      type: Array,
      required: false,
      default: null,
    },
    help: {
      type: String,
      required: false,
      default: null,
    },
    name: {
      type: String,
      required: true,
    },
    placeholder: {
      type: String,
      required: false,
      default: null,
    },
    required: {
      type: Boolean,
      required: false,
    },
    title: {
      type: String,
      required: false,
      default: null,
    },
    type: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      model: this.value,
    };
  },
  computed: {
    isCheckbox() {
      return this.type === 'checkbox';
    },
    isPassword() {
      return this.type === 'password';
    },
    isSelect() {
      return this.type === 'select';
    },
    isTextarea() {
      return this.type === 'textarea';
    },
    isNonEmptyPassword() {
      return this.isPassword && !isEmpty(this.value);
    },
    label() {
      if (this.isNonEmptyPassword) {
        return sprintf(__('Enter new %{field_title}'), {
          field_title: this.computedTitle,
        });
      }
      return this.computedTitle;
    },
    passwordRequired() {
      return isEmpty(this.value) && this.required;
    },
    computedTitle() {
      return this.title || startCase(this.name);
    },
    options() {
      return this.choices.map(choice => {
        return {
          value: choice[1],
          text: choice[0],
        };
      });
    },
    fieldId() {
      return `service_${this.name}`;
    },
    fieldName() {
      return `service[${this.name}]`;
    },
  },
  created() {
    if (this.isNonEmptyPassword) {
      this.model = null;
    }
  },
};
</script>

<template>
  <gl-form-group :label="label" :label-for="fieldId" :description="help">
    <template v-if="isCheckbox">
      <input :name="fieldName" type="hidden" value="false" />
      <gl-form-checkbox :id="fieldId" v-model="model" :name="fieldName" />
    </template>

    <gl-form-select
      v-else-if="isSelect"
      :id="fieldId"
      v-model="model"
      :name="fieldName"
      :options="options"
    />
    <gl-form-textarea
      v-else-if="isTextarea"
      :id="fieldId"
      v-model="model"
      :name="fieldName"
      :placeholder="placeholder"
      :required="required"
    />
    <gl-form-input
      v-else-if="isPassword"
      :id="fieldId"
      v-model="model"
      :name="fieldName"
      :type="type"
      autocomplete="new-password"
      :placeholder="placeholder"
      :required="passwordRequired"
    />
    <gl-form-input
      v-else
      :id="fieldId"
      v-model="model"
      :name="fieldName"
      :type="type"
      :placeholder="placeholder"
      :required="required"
    />
  </gl-form-group>
</template>
