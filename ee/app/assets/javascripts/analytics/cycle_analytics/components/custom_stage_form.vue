<script>
import { isEqual } from 'underscore';
import { GlFormGroup, GlFormInput, GlFormSelect, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
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

const defaultFields = {
  id: null,
  name: null,
  startEventIdentifier: null,
  startEventLabelId: null,
  endEventIdentifier: null,
  endEventLabelId: null,
};

export default {
  components: {
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
      default: () => {},
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
    errors: {
      type: Object,
      required: false,
      default: () => {},
    },
  },
  data() {
    return {
      labelEvents: getLabelEventsIdentifiers(this.events),
      fields: {},
    };
  },
  computed: {
    defaultFieldData() {
      return {
        ...defaultFields,
        ...this.initialFields,
      };
    },
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
      if (!this.hasValidStartAndEndEventPair) {
        return false;
      }
      const {
        fields: {
          name,
          startEventIdentifier,
          startEventLabelId,
          endEventIdentifier,
          endEventLabelId,
        },
      } = this;

      const requiredFields = [startEventIdentifier, endEventIdentifier, name];
      if (this.startEventRequiresLabel) {
        requiredFields.push(startEventLabelId);
      }
      if (this.endEventRequiresLabel) {
        requiredFields.push(endEventLabelId);
      }
      return requiredFields.every(
        fieldValue => fieldValue && (fieldValue.length > 0 || fieldValue > 0),
      );
    },
    isDirty() {
      return !isEqual(this.initialFields, this.fields) && !isEqual(defaultFields, this.fields);
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
    this.resetFormFields();
  },
  // updated() {
  //   this.resetFormFields();
  // },
  methods: {
    resetFormFields() {
      this.fields = this.defaultFieldData;
      // console.log('this.fields', this.fields);
      // console.log('this.initialFields', this.initialFields);
      // console.log('defaultFields', defaultFields);
      // Object.entries(this.defaultFieldData).
      // for (let [key, value] of Object.entries(this.defaultFieldData)) {
      //   // console.log('setting', key, value);
      //   this.$set(this.fields, key, value);
      // }
      // console.log('this.fields', this.fields);
    },
    handleCancel() {
      this.resetFormFields();
      this.$emit('cancel');
    },
    handleSave() {
      const data = convertObjectPropsToSnakeCase(this.fields);
      if (this.isEditingCustomStage) {
        const { id } = this.initialFields;
        this.$emit(STAGE_ACTIONS.UPDATE, { ...data, id });
      } else {
        this.$emit(STAGE_ACTIONS.CREATE, data);
      }
    },
    handleSelectLabel(key, labelId) {
      this.fields[key] = labelId;
    },
    handleClearLabel(key) {
      this.fields[key] = null;
    },
    isValid(key) {
      return !this.isDirty || !this.errors || !this.errors[key];
    },
    fieldErrors(key) {
      return !this.isValid(key) ? this.errors[key].join('\n') : null;
    },
    onUpdateFormField() {
      if (this.errors) this.$emit('clearErrors');
    },
  },
};
</script>
<template>
  <form class="custom-stage-form m-4 mt-0">
    <div class="mb-1">
      <h4>{{ formTitle }}</h4>
    </div>
    <gl-form-group
      :label="s__('CustomCycleAnalytics|Name')"
      :state="isValid('name')"
      :invalid-feedback="fieldErrors('name')"
    >
      <gl-form-input
        v-model="fields.name"
        class="form-control"
        type="text"
        name="custom-stage-name"
        :placeholder="s__('CustomCycleAnalytics|Enter a name for the stage')"
        required
        @change="onUpdateFormField"
      />
    </gl-form-group>
    <div class="d-flex" :class="{ 'justify-content-between': startEventRequiresLabel }">
      <div :class="[startEventRequiresLabel ? 'w-50 mr-1' : 'w-100']">
        <gl-form-group
          :label="s__('CustomCycleAnalytics|Start event')"
          :state="isValid('startEventIdentifier')"
          :invalid-feedback="fieldErrors('startEventIdentifier')"
        >
          <gl-form-select
            v-model="fields.startEventIdentifier"
            name="custom-stage-start-event"
            :required="true"
            :options="startEventOptions"
            @change="onUpdateFormField"
          />
        </gl-form-group>
      </div>
      <div v-if="startEventRequiresLabel" class="w-50 ml-1">
        <gl-form-group
          :label="s__('CustomCycleAnalytics|Start event label')"
          :state="isValid('startEventLabelId')"
          :invalid-feedback="fieldErrors('startEventLabelId')"
        >
          <labels-selector
            :labels="labels"
            :selected-label-id="fields.startEventLabelId"
            name="custom-stage-start-event-label"
            @selectLabel="handleSelectLabel('startEventLabelId', $event)"
            @clearLabel="handleClearLabel('startEventLabelId')"
            @change="onUpdateFormField"
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
          :state="isValid('endEventIdentifier')"
          :invalid-feedback="fieldErrors('endEventIdentifier') || endEventError"
        >
          <!-- :state="hasValidStartAndEndEventPair"
          :invalid-feedback="endEventError" -->
          <gl-form-select
            v-model="fields.endEventIdentifier"
            name="custom-stage-stop-event"
            :options="endEventOptions"
            :required="true"
            :disabled="!hasStartEvent"
            @change="onUpdateFormField"
          />
        </gl-form-group>
      </div>
      <div v-if="endEventRequiresLabel" class="w-50 ml-1">
        <gl-form-group
          :label="s__('CustomCycleAnalytics|Stop event label')"
          :state="isValid('endEventLabelId')"
          :invalid-feedback="fieldErrors('endEventLabelId')"
        >
          <labels-selector
            :labels="labels"
            :selected-label-id="fields.endEventLabelId"
            name="custom-stage-stop-event-label"
            @selectLabel="handleSelectLabel('endEventLabelId', $event)"
            @clearLabel="handleClearLabel('endEventLabelId')"
            @change="onUpdateFormField"
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
