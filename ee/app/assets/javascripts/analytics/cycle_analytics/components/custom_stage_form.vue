<script>
import { isEqual } from 'underscore';
import { GlButton, GlFormGroup, GlFormInput, GlFormSelect } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

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
    LabelsSelector,
  },
  props: {
    events: {
      type: Array,
      // required: true,
      required: false,
      default: () =>
        [
          {
            name: __('Issue created'),
            identifier: 'issue_created',
            type: 'simple',
            can_be_start_event: true,
            allowed_end_events: ['issue_stage_end'],
          },
          {
            name: __('Issue first mentioned in a commit'),
            identifier: 'issue_first_mentioned_in_commit',
            type: 'simple',
            can_be_start_event: false,
            allowed_end_events: [],
          },
          {
            name: __('Merge request created'),
            identifier: 'merge_request_created',
            type: 'simple',
            can_be_start_event: true,
            allowed_end_events: ['merge_request_merged'],
          },

          {
            name: __('Merge request first deployed to production'),
            identifier: 'merge_request_first_deployed_to_production',
            type: 'simple',
            can_be_start_event: false,
            allowed_end_events: [],
          },
          {
            name: __('Merge request last build finish time'),
            identifier: 'merge_request_last_build_finished',
            type: 'simple',
            can_be_start_event: false,
            allowed_end_events: [],
          },
          {
            name: __('Merge request last build start time'),
            identifier: 'merge_request_last_build_started',
            type: 'simple',
            can_be_start_event: true,
            allowed_end_events: ['merge_request_last_build_finished'],
          },
          {
            name: __('Merge request merged'),
            identifier: 'merge_request_merged',
            type: 'simple',
            can_be_start_event: true,
            allowed_end_events: ['merge_request_first_deployed_to_production'],
          },
          {
            name: __('Issue first mentioned in a commit'),
            identifier: 'code_stage_start',
            type: 'simple',
            can_be_start_event: true,
            allowed_end_events: ['merge_request_created'],
          },
          {
            name: __('Issue first associated with a milestone or issue first added to a board'),
            identifier: 'issue_stage_end',
            type: 'simple',
            can_be_start_event: false,
            allowed_end_events: [],
          },
          {
            name: __('Issue first associated with a milestone or issue first added to a board'),
            identifier: 'plan_stage_start',
            type: 'simple',
            can_be_start_event: true,
            allowed_end_events: ['issue_first_mentioned_in_commit'],
          },
          {
            identifier: 'issue_label_added',
            name: __('Issue Label Added'),
            type: 'label',
            can_be_start_event: true,
            allowed_end_events: ['issue_closed', 'issue_label_removed'],
          },
          {
            identifier: 'issue_label_removed',
            name: __('Issue Label Removed'),
            type: 'label',
            can_be_start_event: false,
            allowed_end_events: [],
          },
        ].map(e => convertObjectPropsToCamelCase(e)),
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
      return requiredFields.every(fieldValue => fieldValue && fieldValue.length > 0);
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
        ? s__('CustomCycleAnalyticsStart event changed, please select a valid stop event')
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
      this.$emit('submit', this.fields);
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
  <form class="add-stage-form m-4">
    <div class="mb-1">
      <h4>{{ s__('CustomCycleAnalytics|New stage') }}</h4>
    </div>
    <gl-form-group :label="s__('CustomCycleAnalytics|Name')">
      <gl-form-input
        v-model="fields.name"
        class="form-control"
        type="text"
        name="add-stage-name"
        :placeholder="s__('CustomCycleAnalytics|Enter a name for the stage')"
        required
      />
    </gl-form-group>
    <div class="d-flex" :class="{ 'justify-content-between': startEventRequiresLabel }">
      <div :class="[startEventRequiresLabel ? 'w-50 mr-1' : 'w-100']">
        <gl-form-group :label="s__('CustomCycleAnalytics|Start event')">
          <gl-form-select
            v-model="fields.startEvent"
            name="add-stage-start-event"
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
            name="add-stage-start-event-label"
            @selectLabel="labelId => handleSelectLabel('startEventLabel', labelId)"
            @clearLabel="handleClearLabel"
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
            name="add-stage-stop-event"
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
            name="add-stage-stop-event-label"
            @selectLabel="labelId => handleSelectLabel('stopEventLabel', labelId)"
            @clearLabel="handleClearLabel"
          />
        </gl-form-group>
      </div>
    </div>

    <div class="add-stage-form-actions">
      <button
        :disabled="!isDirty"
        class="btn btn-cancel js-add-stage-cancel"
        type="button"
        @click="handleCancel"
      >
        {{ __('Cancel') }}
      </button>
      <button
        :disabled="!isComplete || !isDirty"
        type="button"
        class="js-add-stage btn btn-success"
        @click="handleSave"
      >
        {{ s__('CustomCycleAnalytics|Add stage') }}
      </button>
    </div>
  </form>
</template>
