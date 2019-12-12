<script>
import { GlLink, GlProgressBar, GlButton, GlLoadingIcon } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import userAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import Icon from '~/vue_shared/components/icon.vue';
import HelpContentPopover from './help_content_popover.vue';
import TourPartsList from './tour_parts_list.vue';
import Tracking from '~/tracking';

export default {
  name: 'OnboardingHelper',
  components: {
    userAvatarImage,
    Icon,
    GlLink,
    GlProgressBar,
    GlButton,
    GlLoadingIcon,
    HelpContentPopover,
    TourPartsList,
  },
  props: {
    tourTitles: {
      type: Array,
      required: true,
    },
    activeTour: {
      type: Number,
      required: false,
      default: null,
    },
    totalStepsForTour: {
      type: Number,
      required: false,
      default: 0,
    },
    helpContent: {
      type: Object,
      required: false,
      default: null,
    },
    percentageCompleted: {
      type: Number,
      required: false,
      default: 0,
    },
    completedSteps: {
      type: Number,
      required: false,
      default: 0,
    },
    initialShow: {
      type: Boolean,
      required: false,
      default: false,
    },
    dismissPopover: {
      type: Boolean,
      required: false,
      default: false,
    },
    goldenTanukiSvgPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      expanded: false,
      showPopover: false,
      popoverDismissed: false,
      helpContentTrigger: null,
      showLoadingIcon: false,
    };
  },
  computed: {
    totalTours() {
      return this.tourTitles.length;
    },
    tourInfo() {
      return sprintf(s__('UserOnboardingTour|%{activeTour}/%{totalTours}'), {
        activeTour: this.activeTour,
        totalTours: this.totalTours,
      });
    },
    hasTourTitles() {
      return this.totalTours > 0;
    },
    toggleButtonLabel() {
      return this.expanded ? __('Close') : __('More');
    },
    toggleButtonIcon() {
      return this.expanded ? 'close' : 'ellipsis_h';
    },
    showLink() {
      return this.activeTour && Boolean(this.helpContent);
    },
  },
  watch: {
    initialShow(newVal) {
      if (newVal) {
        this.showPopover = newVal;
      }
    },
    dismissPopover(newVal) {
      this.popoverDismissed = newVal;

      if (newVal) {
        this.showPopover = false;
      }
    },
  },
  mounted() {
    this.helpContentTrigger = this.$refs.onboardingHelper;
  },
  methods: {
    transitionEndCallback() {
      if (!this.popoverDismissed && !this.expanded) {
        this.showPopover = true;
      }
    },
    toggleMenu() {
      this.expanded = !this.expanded;

      if (!this.popoverDismissed && this.expanded) {
        this.showPopover = false;
      }
    },
    skipStep() {
      this.showLoadingIcon = true;
      this.$emit('skipStep');
    },
    restartStep() {
      this.$emit('restartStep');
    },
    beginExitTourProcess() {
      if (Tracking.enabled()) {
        this.$emit('showFeedbackContent', true);
      } else {
        this.$emit('showDntExitContent', true);
      }
    },
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
  <div
    id="js-onboarding-helper"
    ref="onboardingHelper"
    class="onboarding-helper-container d-none d-lg-block position-fixed"
    :class="{ expanded: expanded }"
    @click="toggleMenu"
    @transitionend="transitionEndCallback"
  >
    <help-content-popover
      v-if="helpContent && helpContentTrigger"
      :help-content="helpContent"
      :target="helpContentTrigger"
      :show="showPopover"
      :disabled="popoverDismissed"
      @clickStepContentButton="callStepContentButton"
      @clickExitTourButton="callExitTour"
      @clickFeedbackButton="submitFeedback"
    />
    <div class="d-flex align-items-center cursor-pointer">
      <div class="avatar s48 mr-1 d-flex">
        <img
          v-if="!showLoadingIcon"
          :src="goldenTanukiSvgPath"
          :alt="s__('Golden Tanuki')"
          class="m-auto"
        />
        <gl-loading-icon v-else :inline="true" class="m-auto" />
      </div>
      <div class="d-flex flex-grow justify-content-between">
        <div class="qa-headline">
          <strong class="title">{{ s__('UserOnboardingTour|Learn GitLab') }}</strong>
          <strong v-if="activeTour">{{ tourInfo }}</strong>
          <gl-progress-bar class="mt-1" :value="percentageCompleted" variant="info" />
        </div>
        <gl-button
          class="qa-toggle-btn btn btn-transparent mr-1"
          type="button"
          :aria-label="toggleButtonLabel"
        >
          <icon :size="14" :name="toggleButtonIcon" />
        </gl-button>
      </div>
    </div>
    <div class="collapsible overflow-hidden">
      <div v-if="hasTourTitles" class="qa-tour-parts-list">
        <tour-parts-list
          :tour-titles="tourTitles"
          :active-tour="activeTour"
          :total-steps-for-tour="totalStepsForTour"
          :completed-steps="completedSteps"
        />
      </div>
      <hr class="my-2" />
      <ul class="list-unstyled mx-2 mb-2">
        <li v-if="showLink">
          <gl-link class="qa-skip-step-link d-inline-flex" @click="skipStep">
            <icon name="collapse-right" class="mr-1" />
            <span>{{ s__('UserOnboardingTour|Skip this step') }}</span>
          </gl-link>
        </li>
        <li v-if="showLink">
          <gl-link class="qa-restart-step-link d-inline-flex" @click="restartStep">
            <icon name="repeat" class="mr-1" />
            <span>{{ s__('UserOnboardingTour|Restart this step') }}</span>
          </gl-link>
        </li>
        <li>
          <gl-link class="qa-exit-tour-link d-inline-flex" @click="beginExitTourProcess">
            <icon name="leave" class="mr-1" />
            <span>{{ s__("UserOnboardingTour|Exit 'Learn GitLab'") }}</span>
          </gl-link>
        </li>
      </ul>
    </div>
  </div>
</template>
