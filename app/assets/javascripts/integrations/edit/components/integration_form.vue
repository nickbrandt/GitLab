<script>
import eventHub from '../event_hub';
import ActiveToggle from './active_toggle.vue';
import JiraTriggerFields from './jira_trigger_fields.vue';
import TriggerFields from './trigger_fields.vue';
import DynamicField from './dynamic_field.vue';
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  name: 'IntegrationForm',
  components: {
    ActiveToggle,
    JiraTriggerFields,
    TriggerFields,
    DynamicField,
    GlLoadingIcon,
  },
  props: {
    activeToggleProps: {
      type: Object,
      required: true,
    },
    cancelPath: {
      type: String,
      required: false,
      default: null,
    },
    canTest: {
      type: Boolean,
      required: false,
      default: false,
    },
    testPath: {
      type: String,
      required: false,
      default: null,
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
  data() {
    return {
      isSaving: false,
      isTesting: false,
    };
  },
  computed: {
    isJira() {
      return this.type === 'jira';
    },
  },
  methods: {
    onTestClick() {
      this.isTesting = true;
      eventHub.$emit('test');
    },
  },
};
</script>

<template>
  <div>
    <div class="row">
      <div class="col-sm-4">
        <div v-html="helpHtml"></div>
      </div>
      <div class="col-sm-8">
        <active-toggle v-if="showActive" v-bind="activeToggleProps" />
        <jira-trigger-fields v-if="isJira" v-bind="triggerFieldsProps" />
        <trigger-fields v-else-if="triggerEvents.length" :events="triggerEvents" :type="type" />
        <dynamic-field v-for="field in fields" :key="field.name" v-bind="field" />
        <div class="footer-block row-content-block">
          <button type="submit" class="btn btn-success" :disabled="isSaving || isTesting">
            <gl-loading-icon v-show="isSaving" inline color="dark" />
            {{ __('Save') }}
          </button>
          <a
            v-if="canTest"
            :href="testPath"
            class="btn gl-ml-3"
            :disabled="isSaving || isTesting"
            @click.prevent="onTestClick"
          >
            <gl-loading-icon v-show="isTesting" inline color="dark" />
            {{ __('Test settings') }}
          </a>
          <a :href="cancelPath" class="btn btn-cancel">{{ __('Cancel') }}</a>
        </div>
      </div>
    </div>
  </div>
</template>
