<script>
import { isEqual } from 'underscore';
import { GlButton, GlFormGroup, GlFormInput, GlFormSelect, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import LabelsSelector from './labels_selector.vue';
import {
  isStartEvent,
  isLabelEvent,
  getAllowedEndEvents,
  eventToOption,
  eventsByIdentifier,
  getLabelEventsIdentifiers,
} from '../utils';

const initFields = {
  name: '',
  startEvent: '',
  startEventLabel: null,
  stopEvent: '',
  stopEventLabel: null,
};

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlLoadingIcon,
    LabelsSelector,
  },
  props: {
    events: {
      type: Array,
      required: true,
    },
    labels: {
      type: Array,
      required: true,
    },
    initialFields: {
      type: Object,
      required: false,
      default: () => ({
        ...initFields,
      }),
    },
    isSavingCustomStage: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      fields: {
        ...initFields,
      },
    };
  },
  computed: {
    startEventOptions() {
      return [
        { value: null, text: s__('CustomCycleAnalytics|Select start event') },
        ...this.events.filter(isStartEvent).map(eventToOption),
      ];
    },
    stopEventOptions() {
      const stopEvents = getAllowedEndEvents(this.events, this.fields.startEvent);
      return [
        { value: null, text: s__('CustomCycleAnalytics|Select stop event') },
        ...eventsByIdentifier(this.events, stopEvents).map(eventToOption),
      ];
    },
    hasStartEvent() {
      return this.fields.startEvent;
    },
    startEventRequiresLabel() {
      return isLabelEvent(this.labelEvents, this.fields.startEvent);
    },
    stopEventRequiresLabel() {
      return isLabelEvent(this.labelEvents, this.fields.stopEvent);
    },
    isComplete() {
      if (!this.hasValidStartAndStopEventPair) return false;
      const requiredFields = [this.fields.startEvent, this.fields.stopEvent, this.fields.name];
      if (this.startEventRequiresLabel) {
        requiredFields.push(this.fields.startEventLabel);
      }
      if (this.stopEventRequiresLabel) {
        requiredFields.push(this.fields.stopEventLabel);
      }
      return requiredFields.every(
        fieldValue => fieldValue && (fieldValue.length > 0 || fieldValue > 0),
      );
    },
    isDirty() {
      return !isEqual(this.initialFields, this.fields);
    },
    hasValidStartAndStopEventPair() {
      const {
        fields: { startEvent, stopEvent },
      } = this;
      if (startEvent && stopEvent) {
        const stopEvents = getAllowedEndEvents(this.events, startEvent);
        return stopEvents.length && stopEvents.includes(stopEvent);
      }
      return true;
    },
    stopEventError() {
      return !this.hasValidStartAndStopEventPair
        ? s__('CustomCycleAnalytics|Start event changed, please select a valid stop event')
        : null;
    },
  },
  mounted() {
    this.labelEvents = getLabelEventsIdentifiers(this.events);
  },
  methods: {
    handleCancel() {
      this.fields = { ...this.initialFields };
      this.$emit('cancel');
    },
    handleSave() {
      const { startEvent, startEventLabel, stopEvent, stopEventLabel, name } = this.fields;
      this.$emit('submit', {
        name,
        start_event_identifier: startEvent,
        start_event_label_id: startEventLabel,
        end_event_identifier: stopEvent,
        end_event_label_id: stopEventLabel,
      });
    },
    handleSelectLabel(key, labelId = null) {
      this.fields[key] = labelId;
    },
    handleClearLabel(key) {
      this.fields[key] = null;
    },
  },
};
</script>
<template>
  <form class="custom-stage-form m-4 mt-0">
    <div class="mb-1">
      <h4>{{ s__('CustomCycleAnalytics|New stage') }}</h4>
    </div>
    <gl-form-group :label="s__('CustomCycleAnalytics|Name')">
      <gl-form-input
        v-model="fields.name"
        class="form-control"
        type="text"
        name="custom-stage-name"
        :placeholder="s__('CustomCycleAnalytics|Enter a name for the stage')"
        required
      />
    </gl-form-group>
    <div class="d-flex" :class="{ 'justify-content-between': startEventRequiresLabel }">
      <div :class="[startEventRequiresLabel ? 'w-50 mr-1' : 'w-100']">
        <gl-form-group :label="s__('CustomCycleAnalytics|Start event')">
          <gl-form-select
            v-model="fields.startEvent"
            name="custom-stage-start-event"
            :required="true"
            :options="startEventOptions"
          />
        </gl-form-group>
      </div>
      <div v-if="startEventRequiresLabel" class="w-50 ml-1">
        <gl-form-group :label="s__('CustomCycleAnalytics|Start event label')">
          <labels-selector
            :labels="labels"
            :selected-label-id="fields.startEventLabel"
            name="custom-stage-start-event-label"
            @selectLabel="labelId => handleSelectLabel('startEventLabel', labelId)"
            @clearLabel="handleClearLabel('startEventLabel')"
          />
        </gl-form-group>
      </div>
    </div>
    <div class="d-flex" :class="{ 'justify-content-between': stopEventRequiresLabel }">
      <div :class="[stopEventRequiresLabel ? 'w-50 mr-1' : 'w-100']">
        <gl-form-group
          :label="s__('CustomCycleAnalytics|Stop event')"
          :description="
            !hasStartEvent ? s__('CustomCycleAnalytics|Please select a start event first') : ''
          "
          :state="hasValidStartAndStopEventPair"
          :invalid-feedback="stopEventError"
        >
          <gl-form-select
            v-model="fields.stopEvent"
            name="custom-stage-stop-event"
            :options="stopEventOptions"
            :required="true"
            :disabled="!hasStartEvent"
          />
        </gl-form-group>
      </div>
      <div v-if="stopEventRequiresLabel" class="w-50 ml-1">
        <gl-form-group :label="s__('CustomCycleAnalytics|Stop event label')">
          <labels-selector
            :labels="labels"
            :selected-label-id="fields.stopEventLabel"
            name="custom-stage-stop-event-label"
            @selectLabel="labelId => handleSelectLabel('stopEventLabel', labelId)"
            @clearLabel="handleClearLabel('stopEventLabel')"
          />
        </gl-form-group>
      </div>
    </div>

    <div class="custom-stage-form-actions">
      <button
        :disabled="!isDirty"
        class="btn btn-cancel js-custom-stage-form-cancel"
        type="button"
        @click="handleCancel"
      >
        {{ __('Cancel') }}
      </button>
      <button
        :disabled="!isComplete || !isDirty"
        type="button"
        class="js-custom-stage-form-submit btn btn-success"
        @click="handleSave"
      >
        <gl-loading-icon v-if="isSavingCustomStage" size="sm" inline />
        {{ s__('CustomCycleAnalytics|Add stage') }}
      </button>
    </div>
  </form>
</template>
