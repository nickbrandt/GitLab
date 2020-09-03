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
    name: {
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
    enabled: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
  },
  methods: {
  },
  i18n: {
    CUSTOM_VALUE_MESSAGE,
  },
};
</script>

<template>
  <gl-form-group :label-for="name">
    <gl-form-checkbox :id="name" :value="enabled" @input="$emit('input', $event)">
      <span>{{ label }}</span>
      <span v-if="description">({{ description }})</span>
    </gl-form-checkbox>
  </gl-form-group>
</template>
