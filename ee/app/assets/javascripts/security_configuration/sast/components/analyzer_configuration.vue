<script>
import { GlFormCheckbox, GlFormGroup } from '@gitlab/ui';
import DynamicFields from './dynamic_fields.vue';
import { isValidAnalyzerEntity } from './utils';

export default {
  components: {
    GlFormGroup,
    GlFormCheckbox,
    DynamicFields,
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
  computed: {
    hasConfiguration() {
      return this.entity.configuration?.length > 0;
    },
  },
  methods: {
    onToggle(value) {
      const entity = { ...this.entity, enabled: value };
      this.$emit('input', entity);
    },
    onConfigurationUpdate(configuration) {
      const entity = { ...this.entity, configuration };
      this.$emit('input', entity);
    },
  },
};
</script>

<template>
  <gl-form-group>
    <gl-form-checkbox :id="entity.name" :checked="entity.enabled" @input="onToggle">
      <span class="gl-font-weight-bold">{{ entity.label }}</span>
      <span v-if="entity.description" class="gl-text-gray-500">({{ entity.description }})</span>
    </gl-form-checkbox>

    <dynamic-fields
      v-if="hasConfiguration"
      :disabled="!entity.enabled"
      class="gl-ml-6"
      :entities="entity.configuration"
      @input="onConfigurationUpdate"
    />
  </gl-form-group>
</template>
