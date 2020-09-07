<script>
import { GlFormCheckbox } from '@gitlab/ui';
import { isValidAnalyzerEntity } from './utils';

export default {
  components: {
    GlFormCheckbox,
  },
  model: {
    prop: 'entity',
    event: 'input',
  },
  props: {
    // SastCiConfigurationAnalyzersEntity from GraphQL endpoint
    entity: {
      type: Object,
      required: true,
      validator: isValidAnalyzerEntity,
    },
  },
  methods: {
    onToggle(value) {
      const entity = { ...this.entity, enabled: value };
      this.$emit('input', entity);
    },
  },
};
</script>

<template>
  <gl-form-checkbox :id="entity.name" :checked="entity.enabled" @input="onToggle">
    <span class="gl-font-weight-bold">{{ entity.label }}</span>
    <span v-if="entity.description" class="gl-text-gray-500">({{ entity.description }})</span>
  </gl-form-checkbox>
</template>
