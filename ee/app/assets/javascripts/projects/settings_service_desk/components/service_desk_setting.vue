<script>
import { GlButton, GlFormSelect, GlToggle, GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import tooltip from '~/vue_shared/directives/tooltip';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import eventHub from '../event_hub';

export default {
  name: 'ServiceDeskSetting',
  directives: {
    tooltip,
  },
  components: {
    ClipboardButton,
    GlButton,
    GlFormSelect,
    GlToggle,
    GlLoadingIcon,
  },
  props: {
    isEnabled: {
      type: Boolean,
      required: true,
    },
    incomingEmail: {
      type: String,
      required: false,
      default: '',
    },
    initialSelectedTemplate: {
      type: String,
      required: false,
      default: '',
    },
    initialOutgoingName: {
      type: String,
      required: false,
      default: '',
    },
    templates: {
      type: Array,
      required: false,
      default: () => [],
    },
    isTemplateSaving: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      selectedTemplate: this.initialSelectedTemplate,
      outgoingName: this.initialOutgoingName || __('GitLab Support Bot'),
    };
  },
  computed: {
    templateOptions() {
      return [''].concat(this.templates);
    },
  },
  methods: {
    onCheckboxToggle(isChecked) {
      eventHub.$emit('serviceDeskEnabledCheckboxToggled', isChecked);
    },
    onSaveTemplate() {
      eventHub.$emit('serviceDeskTemplateSave', {
        selectedTemplate: this.selectedTemplate,
        outgoingName: this.outgoingName,
      });
    },
  },
};
</script>

<template>
  <div>
    <gl-toggle
      id="service-desk-checkbox"
      :value="isEnabled"
      class="d-inline-block align-middle mr-1"
      :label-on="__('Service Desk is on')"
      :label-off="__('Service Desk is off')"
      @change="onCheckboxToggle"
    />
    <label class="align-middle" for="service-desk-checkbox">{{
      __('Activate Service Desk')
    }}</label>
    <div v-if="isEnabled" class="row mt-3">
      <div class="col-md-9 mb-0">
        <strong id="incoming-email-describer" class="d-block mb-1">{{
          __('Forward external support email address to')
        }}</strong>
        <template v-if="incomingEmail">
          <div class="input-group">
            <input
              ref="service-desk-incoming-email"
              type="text"
              class="form-control incoming-email h-auto"
              :placeholder="__('Incoming email')"
              :aria-label="__('Incoming email')"
              aria-describedby="incoming-email-describer"
              :value="incomingEmail"
              disabled="true"
            />
            <div class="input-group-append">
              <clipboard-button
                :title="__('Copy')"
                :text="incomingEmail"
                css-class="btn qa-clipboard-button"
              />
            </div>
          </div>
        </template>
        <template v-else>
          <gl-loading-icon :inline="true" />
          <span class="sr-only">{{ __('Fetching incoming email') }}</span>
        </template>

        <label for="service-desk-template-select" class="mt-3">{{
          __('Template to append to all Service Desk issues')
        }}</label>
        <gl-form-select
          id="service-desk-template-select"
          v-model="selectedTemplate"
          :options="templateOptions"
        />
        <label for="service-desk-email-from-name" class="mt-3">{{
          __('Email display name')
        }}</label>
        <input id="service-desk-email-from-name" v-model.trim="outgoingName" class="form-control" />
        <span class="form-text text-muted mb-3">{{
          __('Emails sent from Service Desk will have this name')
        }}</span>
        <gl-button variant="success" :disabled="isTemplateSaving" @click="onSaveTemplate">{{
          __('Save template')
        }}</gl-button>
      </div>
    </div>
  </div>
</template>
