<script>
import { s__ } from '~/locale';
import { GlButton, GlFormGroup, GlFormInput, GlFormSelect } from '@gitlab/ui';

const isStartEvent = ev => ev && ev.can_be_start_event;
const eventToOption = ({ name: text = '', identifier: value = null }) => ({
  text,
  value,
});

const getAllowedStopEvents = (events = [], targetIdentifier = null) => {
  if (!targetIdentifier || !events.length) return [];
  const st = events.find(({ identifier }) => identifier === targetIdentifier);
  return st.allowed_end_events;
};

const eventsByIdentifier = (events = [], targetIdentifier = []) => {
  if (!targetIdentifier.length || !events.length) return [];
  return events.filter(({ identifier }) => targetIdentifier.indexOf(identifier) > -1);
};

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
  },
  props: {
    events: {
      type: Array,
      required: true,
    },
    // name: {
    //   type: String,
    //   default: null,
    // },
    // objectType: {
    //   type: String,
    //   default: null,
    // },
    // startEvent: {
    //   type: String,
    //   default: null,
    // },
    // stopEvent: {
    //   type: String,
    //   default: null,
    // },
  },
  data() {
    return {
      fields: {
        // objectType: null,
        name: '',
        startEvent: '',
        startEventLabel: '',
        stopEvent: '',
        stopEventLabel: '',
      },
    };
  },
  computed: {
    stopEventOptions() {
      const stopEvents = getAllowedStopEvents(this.events, this.fields.startEvent);
      return [
        { value: null, text: s__('CustomCycleAnalytics|Select stop event') },
        ...eventsByIdentifier(this.events, stopEvents).map(eventToOption),
      ];
    },
    startEventOptions() {
      return [
        { value: null, text: s__('CustomCycleAnalytics|Select start event') },
        ...this.events.filter(isStartEvent).map(eventToOption),
      ];
    },
    hasStartEvent() {
      return this.fields.startEvent;
    },
    // startEventRequiresLabel() {},
    // stopEventRequiresLabel() {},
    isComplete() {
      // TODO: need to factor in label field
      const requiredFields = [this.fields.startEvent, this.fields.stopEvent, this.fields.name];
      return requiredFields.every(fieldValue => fieldValue && fieldValue.length > 0);
    },
  },
  methods: {
    handleSave() {
      this.$emit('submit', this.fields);
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
        value=""
        name="add-stage-name"
        :placeholder="s__('CustomCycleAnalytics|Enter a name for the stage')"
        required
      />
    </gl-form-group>
    <gl-form-group :label="s__('CustomCycleAnalytics|Start event')">
      <gl-form-select
        v-model="fields.startEvent"
        name="add-stage-start-event"
        :required="true"
        :options="startEventOptions"
      />
    </gl-form-group>
    <gl-form-group
      :label="s__('CustomCycleAnalytics|Stop event')"
      :description="s__('CustomCycleAnalytics|Please select a start event first')"
    >
      <gl-form-select
        v-model="fields.stopEvent"
        name="add-stage-stop-event"
        :options="stopEventOptions"
        :required="true"
        :disabled="!hasStartEvent"
      />
    </gl-form-group>
    <div class="add-stage-form-actions">
      <!-- 
          TODO: what does the cancel button do?
          - Just hide the form?
          - clear entered data?
        -->
      <button class="btn btn-cancel add-stage-cancel" type="button" @click="cancelHandler()">
        {{ __('Cancel') }}
      </button>
      <button
        :disabled="!isComplete"
        type="button"
        class="js-add-stage btn btn-success"
        @click="handleSave"
      >
        {{ s__('CustomCycleAnalytics|Add stage') }}
      </button>
    </div>
  </form>
</template>
