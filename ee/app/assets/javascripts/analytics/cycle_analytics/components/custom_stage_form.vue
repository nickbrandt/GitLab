<script>
import { isEqual } from 'underscore';
import { GlButton, GlFormGroup, GlFormInput, GlFormSelect, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import LabelsSelector from './labels_selector.vue';
import { STAGE_ACTIONS } from '../constants';
import {
  isStartEvent,
  isLabelEvent,
  getAllowedEndEvents,
  eventToOption,
  eventsByIdentifier,
  getLabelEventsIdentifiers,
} from '../utils';

const initFields = {
  id: null,
  name: null,
  startEventIdentifier: null,
  startEventLabelId: null,
  endEventIdentifier: null,
  endEventLabelId: null,
};

// TODO: should be a util / use a util if exists...
const snakeFields = (fields = {}) =>
  Object.entries(fields).reduce((acc, curr) => {
    const [key, value] = curr;
    return { ...acc, [convertToSnakeCase(key)]: value };
  }, {});

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
    isEditingCustomStage: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      fields: {
        ...this.initialFields,
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
    endEventOptions() {
      const endEvents = getAllowedEndEvents(this.events, this.fields.startEventIdentifier);
      return [
        { value: null, text: s__('CustomCycleAnalytics|Select stop event') },
        ...eventsByIdentifier(this.events, endEvents).map(eventToOption),
      ];
    },
    hasStartEvent() {
      return this.fields.startEventIdentifier;
    },
    startEventRequiresLabel() {
      return isLabelEvent(this.labelEvents, this.fields.startEventIdentifier);
    },
    endEventRequiresLabel() {
      return isLabelEvent(this.labelEvents, this.fields.endEventIdentifier);
    },
    isComplete() {
      if (!this.hasValidStartAndEndEventPair) return false;
      const requiredFields = [
        this.fields.startEventIdentifier,
        this.fields.endEventIdentifier,
        this.fields.name,
      ];
      if (this.startEventRequiresLabel) {
        requiredFields.push(this.fields.startEventLabelId);
      }
      if (this.endEventRequiresLabel) {
        requiredFields.push(this.fields.endEventLabelId);
      }
      return requiredFields.every(
        fieldValue => fieldValue && (fieldValue.length > 0 || fieldValue > 0),
      );
    },
    isDirty() {
      return !isEqual(this.initialFields, this.fields);
    },
    hasValidStartAndEndEventPair() {
      const {
        fields: { startEventIdentifier, endEventIdentifier },
      } = this;
      if (startEventIdentifier && endEventIdentifier) {
        const endEvents = getAllowedEndEvents(this.events, startEventIdentifier);
        return endEvents.length && endEvents.includes(endEventIdentifier);
      }
      return true;
    },
    endEventError() {
      return !this.hasValidStartAndEndEventPair
        ? s__('CustomCycleAnalytics|Start event changed, please select a valid stop event')
        : null;
    },
    saveStageText() {
      return this.isEditingCustomStage
        ? s__('CustomCycleAnalytics|Update stage')
        : s__('CustomCycleAnalytics|Add stage');
    },
    formTitle() {
      return this.isEditingCustomStage
        ? s__('CustomCycleAnalytics|Editing stage')
        : s__('CustomCycleAnalytics|New stage');
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
      const data = snakeFields(this.fields);
      if (this.isEditingCustomStage) {
        const { id } = this.initialFields;
        this.$emit(STAGE_ACTIONS.UPDATE, { ...data, id });
      } else {
        this.$emit(STAGE_ACTIONS.CREATE, data);
      }
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
      <h4>{{ formTitle }}</h4>
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
            v-model="fields.startEventIdentifier"
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
            :selected-label-id="fields.startEventLabelId"
            name="custom-stage-start-event-label"
            @selectLabel="labelId => handleSelectLabel('startEventLabelId', labelId)"
            @clearLabel="handleClearLabel('startEventLabelId')"
          />
        </gl-form-group>
      </div>
    </div>
    <div class="d-flex" :class="{ 'justify-content-between': endEventRequiresLabel }">
      <div :class="[endEventRequiresLabel ? 'w-50 mr-1' : 'w-100']">
        <gl-form-group
          :label="s__('CustomCycleAnalytics|Stop event')"
          :description="
            !hasStartEvent ? s__('CustomCycleAnalytics|Please select a start event first') : ''
          "
          :state="hasValidStartAndEndEventPair"
          :invalid-feedback="endEventError"
        >
          <gl-form-select
            v-model="fields.endEventIdentifier"
            name="custom-stage-stop-event"
            :options="endEventOptions"
            :required="true"
            :disabled="!hasStartEvent"
          />
        </gl-form-group>
      </div>
      <div v-if="endEventRequiresLabel" class="w-50 ml-1">
        <gl-form-group :label="s__('CustomCycleAnalytics|Stop event label')">
          <labels-selector
            :labels="labels"
            :selected-label-id="fields.endEventLabelId"
            name="custom-stage-stop-event-label"
            @selectLabel="labelId => handleSelectLabel('endEventLabelId', labelId)"
            @clearLabel="handleClearLabel('endEventLabelId')"
          />
        </gl-form-group>
      </div>
    </div>

    <div class="custom-stage-form-actions">
      <button
        :disabled="!isDirty"
        class="btn btn-cancel js-save-stage-cancel"
        type="button"
        @click="handleCancel"
      >
        {{ __('Cancel') }}
      </button>
      <button
        :disabled="!isComplete || !isDirty"
        type="button"
        class="js-save-stage btn btn-success"
        @click="handleSave"
      >
        <gl-loading-icon v-if="isSavingCustomStage" size="sm" inline />
        {{ saveStageText }}
      </button>
    </div>
  </form>
</template>
