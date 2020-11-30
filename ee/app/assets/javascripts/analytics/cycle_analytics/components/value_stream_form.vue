<script>
import {
  GlButton,
  GlButtonGroup,
  GlForm,
  GlFormInput,
  GlFormGroup,
  GlModal,
  GlFormRadioGroup,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import { mapState, mapActions } from 'vuex';
import { sprintf, __, s__ } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
// import { DEFAULT_STAGE_NAMES } from '../../constants';
import { DATA_REFETCH_DELAY } from '../../shared/constants';

const ERRORS = {
  MIN_LENGTH: s__('CreateValueStreamForm|Name is required'),
  MAX_LENGTH: s__('CreateValueStreamForm|Maximum length 100 characters'),
};

const defaultStageFields = {
  name: '',
  isCustom: true, // ? maybe?
  startEventIdentifier: null,
  startEventLabelId: null,
  endEventIdentifier: null,
  endEventLabelId: null,
};

const validate = ({ name }) => {
  const errors = { name: [] };
  if (name.length > 100) {
    errors.name.push(ERRORS.MAX_LENGTH);
  }
  if (!name.length) {
    errors.name.push(ERRORS.MIN_LENGTH);
  }
  return errors;
};

const PRESET_OPTIONS = [
  {
    text: s__('CreateValueStreamForm|From default template'),
    value: 'default',
  },
  {
    text: s__('CreateValueStreamForm|From scratch'),
    value: 'scratch',
  },
];

const DEFAULT_STAGE_CONFIG = ['issue', 'plan', 'code', 'test', 'review', 'staging', 'total'].map(
  id => ({
    id,
    title: capitalizeFirstCharacter(id),
    hidden: false,
    custom: false,
  }),
);

export default {
  name: 'ValueStreamForm',
  components: {
    GlButton,
    GlButtonGroup,
    GlForm,
    GlFormInput,
    GlFormGroup,
    GlModal,
    GlFormRadioGroup,
  },
  props: {
    initialData: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    console.log('DEFAULT_STAGE_CONFIG', DEFAULT_STAGE_CONFIG);
    return {
      errors: {},
      name: '',
      selectedPreset: PRESET_OPTIONS[0].value,
      presetOptions: PRESET_OPTIONS,
      stages: [...DEFAULT_STAGE_CONFIG, { ...defaultStageFields }],
      ...this.initialData,
    };
  },
  computed: {
    ...mapState({
      initialFormErrors: 'createValueStreamErrors',
      isCreating: 'isCreatingValueStream',
    }),
    isValid() {
      return !this.errors.name?.length;
    },
    invalidFeedback() {
      return this.errors.name?.join('\n');
    },
    hasFormErrors() {
      const { initialFormErrors } = this;
      return Boolean(Object.keys(initialFormErrors).length);
    },
    isLoading() {
      return this.isCreating;
    },
  },
  watch: {
    initialFormErrors(newErrors = {}) {
      this.errors = newErrors;
    },
  },
  mounted() {
    const { initialFormErrors } = this;
    if (this.hasFormErrors) {
      this.errors = initialFormErrors;
    } else {
      this.onHandleInput();
    }
    console.log('mounted', this.stages);
  },
  methods: {
    ...mapActions(['createValueStream']),
    onHandleInput: debounce(function debouncedValidation() {
      const { name } = this;
      this.errors = validate({ name });
    }, DATA_REFETCH_DELAY),
    onAddStage() {
      this.stages.push({ ...defaultStageFields });
    },
    isFirstStage(i) {
      return i === 0;
    },
    isLastStage(i) {
      return i === this.stages.length;
    },
    onSubmit() {
      const { name } = this;
      return this.createValueStream({ name }).then(() => {
        if (!this.hasFormErrors) {
          this.$toast.show(sprintf(__("'%{name}' Value Stream created"), { name }), {
            position: 'top-center',
          });
          this.name = '';
        }
      });
    },
  },
};
</script>
<template>
  <gl-modal
    data-testid="value-stream-form-modal"
    modal-id="value-stream-form-modal"
    :title="__('Value Stream Name')"
    :action-secondary="{
      text: s__('CreateValueStreamForm|Add another stage'),
      attributes: [{ variant: 'info' }],
    }"
    :action-primary="{
      text: s__('CreateValueStreamForm|Create Value Stream'),
      attributes: [
        { variant: 'success' },
        {
          disabled: !isValid,
        },
        { loading: isLoading },
      ],
    }"
    :action-cancel="{ text: __('Cancel') }"
    @secondary.prevent="onAddStage"
    @primary.prevent="onSubmit"
  >
    <gl-form>
      <gl-form-radio-group v-model="selectedPreset" :options="presetOptions" name="preset" />
      <gl-form-group
        :label="__('Value Stream Name')"
        label-for="create-value-stream-name"
        :invalid-feedback="invalidFeedback"
        :state="isValid"
      >
        <gl-form-input
          id="create-value-stream-name"
          v-model.trim="name"
          name="create-value-stream-name"
          :placeholder="s__('CreateValueStreamForm|Example: My Value Stream')"
          :state="isValid"
          required
          @input="onHandleInput"
        />
      </gl-form-group>
      <hr />
      <gl-form-group
        v-for="(stage, i) in stages"
        :key="stage.id"
        :label="sprintf(__('Stage %{i}'), { i: i + 1 })"
      >
        <gl-form-input
          v-if="stage.custom"
          v-model.trim="stage.title"
          :name="`create-value-stream-stage-${i}`"
          :placeholder="s__('CreateValueStreamForm|Enter stage name')"
          :state="isValid"
          required
          @input="onHandleInput"
        />
        <span v-else>{{ stage.title }}</span>
        <gl-button-group>
          <gl-button :disabled="isFirstStage(i)" icon="arrow-down" />
          <gl-button :disabled="isLastStage(i)" icon="arrow-up" />
        </gl-button-group>
        &nbsp;
        <gl-button icon="archive" />
      </gl-form-group>
    </gl-form>
  </gl-modal>
</template>
