<script>
import ActiveToggle from './active_toggle.vue';
import JiraTriggerFields from './jira_trigger_fields.vue';
import TriggerFields from './trigger_fields.vue';
import DynamicField from './dynamic_field.vue';

export default {
  name: 'IntegrationForm',
  components: {
    ActiveToggle,
    JiraTriggerFields,
    TriggerFields,
    DynamicField,
  },
  props: {
    activeToggleProps: {
      type: Object,
      required: true,
    },
    helpHtml: {
      type: String,
      required: false,
      default: null,
    },
    showActive: {
      type: Boolean,
      required: true,
    },
    triggerFieldsProps: {
      type: Object,
      required: true,
    },
    triggerEvents: {
      type: Array,
      required: false,
      default: () => [],
    },
    fields: {
      type: Array,
      required: false,
      default: () => [],
    },
    type: {
      type: String,
      required: true,
    },
  },
  computed: {
    isJira() {
      return this.type === 'jira';
    },
  },
};
</script>

<template>
  <div>
    <active-toggle v-if="showActive" v-bind="activeToggleProps" />
    <jira-trigger-fields v-if="isJira" v-bind="triggerFieldsProps" />
    <trigger-fields v-else-if="triggerEvents.length" :events="triggerEvents" :type="type" />
    <dynamic-field v-for="field in fields" :key="field.name" v-bind="field" />
    <div class="row">
      <div class="col-sm-4">
        <div v-html="helpHtml"></div>
      </div>
      <div class="col-sm-8">
        <active-toggle v-if="showActive" v-bind="activeToggleProps" />
        <jira-trigger-fields v-if="isJira" v-bind="triggerFieldsProps" />
        <trigger-fields v-else-if="triggerEvents.length" :events="triggerEvents" :type="type" />
        <dynamic-field v-for="field in fields" :key="field.name" v-bind="field" />
      </div>
    </div>
  </div>
</template>
