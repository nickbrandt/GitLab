<script>
import { startCase } from 'lodash';
import { __ } from '~/locale';
import { GlFormGroup, GlFormCheckbox, GlFormInput } from '@gitlab/ui';

export default {
  name: 'TriggerFields',
  components: {
    GlFormGroup,
    GlFormCheckbox,
    GlFormInput,
  },
  props: {
    events: {
      type: Array,
      required: false,
      default: null,
    },
    type: {
      type: String,
      required: true,
    },
  },
  computed: {
    placeholder() {
      if (this.type === 'slack') {
        return __('Slack channels (e.g. general, development)');
      } else if (this.type === 'mattermost') {
        return __('Channel handle (e.g. town-square)');
      }
      return null;
    },
  },
  methods: {
    checkboxName(name) {
      return `service[${name}]`;
    },
    checkboxTitle(title) {
      return startCase(title);
    },
    fieldName(name) {
      return `service[${name}]`;
    },
  },
};
</script>

<template>
  <gl-form-group label="Trigger" label-for="trigger-fields">
    <div id="trigger-fields">
      <gl-form-group v-for="event in events" :key="event.title" :description="event.description">
        <input :name="checkboxName(event.name)" type="hidden" value="false" />
        <gl-form-checkbox v-model="event.value" :name="checkboxName(event.name)">
          {{ checkboxTitle(event.title) }}
        </gl-form-checkbox>
        <gl-form-input
          v-if="event.field.name"
          v-model="event.field.value"
          :name="fieldName(event.field.name)"
          :placeholder="placeholder"
        />
      </gl-form-group>
    </div>
  </gl-form-group>
</template>
