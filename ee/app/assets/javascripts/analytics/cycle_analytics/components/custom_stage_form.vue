<script>
import { mapGetters } from 'vuex';
import { isEqual } from 'underscore';
import {
  GlFormGroup,
  GlFormInput,
  GlFormSelect,
  GlLoadingIcon,
  GlDropdown,
  GlDropdownHeader,
  GlDropdownItem,
} from '@gitlab/ui';
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
    GlDropdown,
    GlDropdownHeader,
    GlDropdownItem,
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
      default: () => ({}),
    },
  },
  data() {
    const defaultErrors = this?.initialFields?.endEventIdentifier
      ? {}
      : { endEventIdentifier: [s__('CustomCycleAnalytics|Please select a start event first')] };
    return {
      labelEvents: getLabelEventsIdentifiers(this.events),
      fields: {
        ...defaultFields,
        ...this.initialFields,
      },
      fieldErrors: {
        ...defaultFields,
        ...this.errors,
        ...defaultErrors,
      },
    };
  },
  computed: {
    ...mapGetters(['hiddenStages']),
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
      if (this.eventMismatchError) {
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
    eventMismatchError() {
      const {
        fields: { startEventIdentifier = null, endEventIdentifier = null },
      } = this;

      if (!startEventIdentifier || !endEventIdentifier) return true;
      const endEvents = getAllowedEndEvents(this.events, startEventIdentifier);
      return !endEvents.length || !endEvents.includes(endEventIdentifier);
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
    hasHiddenStages() {
      return this.hiddenStages.length;
    },
  },
  watch: {
    initialFields(newFields) {
      this.fields = {
        ...defaultFields,
        ...newFields,
      };
      this.fieldErrors = {
        ...defaultFields,
        ...this.errors,
      };
    },
  },
  methods: {
    handleCancel() {
      this.fields = {
        ...defaultFields,
        ...this.initialFields,
      };
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
    hasFieldErrors(key) {
      return this.fieldErrors[key]?.length > 0;
    },
    fieldErrorMessage(key) {
      return this.fieldErrors[key]?.join('\n');
    },
    onUpdateStartEventField() {
      const initVal = this.initialFields?.endEventIdentifier
        ? this.initialFields.endEventIdentifier
        : null;
      this.$set(this.fields, 'endEventIdentifier', initVal);
      this.$set(this.fieldErrors, 'endEventIdentifier', [
        s__('CustomCycleAnalytics|Start event changed, please select a valid stop event'),
      ]);
    },
    onUpdateEndEventField() {
      this.$set(this.fieldErrors, 'endEventIdentifier', null);
    },
    handleRecoverStage(id) {
      this.$emit(STAGE_ACTIONS.UPDATE, { id, hidden: false });
    },
  },
};
</script>
<template>
  <form class="custom-stage-form m-4 mt-0">
    <div class="mb-1 d-flex flex-row justify-content-between">
      <h4>{{ formTitle }}</h4>
      <gl-dropdown :text="__('Recover hidden stage')" class="js-recover-hidden-stage-dropdown">
        <gl-dropdown-header>{{ __('Default stages') }}</gl-dropdown-header>
        <template v-if="hasHiddenStages">
          <gl-dropdown-item
            v-for="stage in hiddenStages"
            :key="stage.id"
            @click="handleRecoverStage(stage.id)"
            >{{ stage.title }}</gl-dropdown-item
          >
        </template>
        <p v-else class="mx-3 my-2">{{ __('All default stages are currently visible') }}</p>
      </gl-dropdown>
    </div>

    <gl-form-group
      ref="name"
      :label="s__('CustomCycleAnalytics|Name')"
      :state="!hasFieldErrors('name')"
      :invalid-feedback="fieldErrorMessage('name')"
    >
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
        <gl-form-group
          ref="startEventIdentifier"
          :label="s__('CustomCycleAnalytics|Start event')"
          :state="!hasFieldErrors('startEventIdentifier')"
          :invalid-feedback="fieldErrorMessage('startEventIdentifier')"
        >
          <gl-form-select
            v-model="fields.startEventIdentifier"
            name="custom-stage-start-event"
            :required="true"
            :options="startEventOptions"
            @change.native="onUpdateStartEventField"
          />
        </gl-form-group>
      </div>
      <div v-if="startEventRequiresLabel" class="w-50 ml-1">
        <gl-form-group
          ref="startEventLabelId"
          :label="s__('CustomCycleAnalytics|Start event label')"
          :state="!hasFieldErrors('startEventLabelId')"
          :invalid-feedback="fieldErrorMessage('startEventLabelId')"
        >
          <labels-selector
            :labels="labels"
            :selected-label-id="fields.startEventLabelId"
            name="custom-stage-start-event-label"
            @selectLabel="handleSelectLabel('startEventLabelId', $event)"
            @clearLabel="handleClearLabel('startEventLabelId')"
          />
        </gl-form-group>
      </div>
    </div>
    <div class="d-flex" :class="{ 'justify-content-between': endEventRequiresLabel }">
      <div :class="[endEventRequiresLabel ? 'w-50 mr-1' : 'w-100']">
        <gl-form-group
          ref="endEventIdentifier"
          :label="s__('CustomCycleAnalytics|Stop event')"
          :state="!hasFieldErrors('endEventIdentifier')"
          :invalid-feedback="fieldErrorMessage('endEventIdentifier')"
          @change.native="onUpdateEndEventField"
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
        <gl-form-group
          ref="endEventLabelId"
          :label="s__('CustomCycleAnalytics|Stop event label')"
          :state="!hasFieldErrors('endEventLabelId')"
          :invalid-feedback="fieldErrorMessage('endEventLabelId')"
        >
          <labels-selector
            :labels="labels"
            :selected-label-id="fields.endEventLabelId"
            name="custom-stage-stop-event-label"
            @selectLabel="handleSelectLabel('endEventLabelId', $event)"
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
