<script>
import { GlPopover, GlButton, GlButtonGroup } from '@gitlab/ui';

export default {
  name: 'HelpContentPopover',
  components: {
    GlPopover,
    GlButton,
    GlButtonGroup,
  },
  props: {
    target: {
      type: HTMLElement,
      required: true,
    },
    helpContent: {
      type: Object,
      required: false,
      default: null,
    },
    placement: {
      type: String,
      required: false,
      default: 'top',
    },
    show: {
      type: Boolean,
      required: false,
      default: false,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    callStepContentButton(button) {
      this.$emit('clickStepContentButton', button);
    },
    callExitTour() {
      this.$emit('clickExitTourButton');
    },
    submitFeedback(button) {
      this.$emit('clickFeedbackButton', button);
    },
  },
};
</script>

<template>
  <gl-popover
    v-bind="$attrs"
    :target="target"
    :placement="placement"
    :show="show"
    :disabled="disabled"
    :css-classes="['onboarding-popover']"
  >
    <div>
      <p v-html="helpContent.text"></p>
      <template v-if="helpContent.buttons">
        <template v-for="(button, index) in helpContent.buttons">
          <gl-button
            v-if="!button.readOnly"
            :key="index"
            :class="button.btnClass"
            class="btn btn-sm mr-2"
            @click="callStepContentButton(button)"
          >
            {{ button.text }}
          </gl-button>
          <span v-else :key="index" :class="button.btnClass" class="btn btn-sm mr-2">
            {{ button.text }}
          </span>
        </template>
      </template>
      <template v-if="helpContent.exitTour">
        <gl-button class="btn btn-sm btn-primary mr-2" @click="callExitTour">
          {{ s__("UserOnboardingTour|Close 'Learn GitLab'") }}
        </gl-button>
      </template>
      <template v-if="helpContent.feedbackButtons">
        <gl-button-group>
          <gl-button
            v-for="feedbackValue in helpContent.feedbackSize"
            :key="feedbackValue"
            @click="
              submitFeedback({
                feedbackResult: feedbackValue,
              })
            "
          >
            {{ feedbackValue }}
          </gl-button>
        </gl-button-group>
        <div class="pt-1">
          <small>{{ __('Not helpful') }}</small>
          <small class="ml-4">{{ __('Very helpful') }}</small>
        </div>
      </template>
    </div>
  </gl-popover>
</template>
