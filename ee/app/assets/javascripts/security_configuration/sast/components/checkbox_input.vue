<script>
import { GlFormGroup, GlFormCheckbox, GlFormText, GlLink, GlSprintf } from '@gitlab/ui';
import { CUSTOM_VALUE_MESSAGE } from './constants';

export default {
  components: {
    GlFormGroup,
    GlFormCheckbox,
    GlFormText,
    GlLink,
    GlSprintf,
  },
  // The DynamicFields component v-binds the configuration entity to this
  // component. This ensures extraneous keys/values are not added as attributes
  // to the underlying GlFormGroup.
  inheritAttrs: false,
  model: {
    prop: 'value',
    event: 'input',
  },
  props: {
    value: {
      type: String,
      required: true,
    },
    defaultValue: {
      type: String,
      required: true,
    },
    field: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
  },
  computed: {
    isCustomValue() {
      return this.value !== this.defaultValue;
    },
  },
  methods: {
    resetToDefaultValue() {
      this.$emit('input', this.defaultValue);
    },
  },
  i18n: {
    CUSTOM_VALUE_MESSAGE,
  },
};
</script>

<template>
  <gl-form-group :label-for="field">
    <template #label>
      {{ label }}
      <gl-form-text class="gl-mt-3">{{ description }}</gl-form-text>
    </template>

    <gl-form-checkbox :id="field" :value="value" @input="$emit('input', $event)" />

    <template v-if="isCustomValue" #description>
      <gl-sprintf :message="$options.i18n.CUSTOM_VALUE_MESSAGE">
        <template #anchor="{ content }">
          <gl-link @click="resetToDefaultValue" v-text="content" />
        </template>
      </gl-sprintf>
    </template>
  </gl-form-group>
</template>
