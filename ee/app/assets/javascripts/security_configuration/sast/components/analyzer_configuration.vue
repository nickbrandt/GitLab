<script>
import { cloneDeep } from 'lodash';
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
  data() {
    return {
      configurationEntities: cloneDeep(this.entity.configuration),
    };
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
    onConfigurationUpdate(value) {
      const entity = { ...this.entity, configuration: formEntities}
      this.$emit('input', entity)
    }
  },
};
</script>

<template>
  <gl-form-group>
    <gl-form-checkbox :id="entity.name" :checked="entity.enabled" @input="onToggle">
      <span class="gl-font-weight-bold">{{ entity.label }}</span>
      <span v-if="entity.description" class="gl-text-gray-500">({{ entity.description }})</span>
    </gl-form-checkbox>    

    <dynamic-fields v-model="configurationEntities" @input="onConfigurationUpdate" />
  </gl-form-group>
</template>
