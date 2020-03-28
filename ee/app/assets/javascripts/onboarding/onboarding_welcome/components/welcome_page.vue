<script>
import { GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import HelpContentPopover from './../../onboarding_helper/components/help_content_popover.vue';
import ActionPopover from './../../onboarding_helper/components/action_popover.vue';
import { redirectTo } from '~/lib/utils/url_utility';
import onboardingUtils from './../../utils';

export default {
  components: {
    GlLink,
    UserAvatarImage,
    HelpContentPopover,
    ActionPopover,
  },
  props: {
    userAvatarUrl: {
      type: String,
      required: false,
      default: '',
    },
    projectFullPath: {
      type: String,
      required: true,
    },
    skipUrl: {
      type: String,
      required: true,
    },
    fromHelpMenu: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      helpText: __(
        "Don't worry, you can access this tour by clicking on the help icon in the top right corner and choose <strong>Learn GitLab</strong>.",
      ),
      helpPopover: {
        target: null,
        content: {
          text: __('White helpers give contextual information.'),
          buttons: [{ text: __('OK'), btnClass: 'btn-primary', readOnly: true }],
        },
      },
      actionPopover: {
        target: null,
        content: __('Blue helpers indicate an action to be taken.'),
        cssClasses: ['blue'],
      },
    };
  },
  computed: {
    skipText() {
      return this.fromHelpMenu ? __('No, not interested right now') : __('Skip this for now');
    },
  },
  mounted() {
    this.helpPopover.target = this.$refs.helpPopoverTrigger;
    this.actionPopover.target = this.$refs.actionPopoverTrigger;
  },
  methods: {
    startTour() {
      onboardingUtils.resetOnboardingLocalStorage();
      onboardingUtils.updateOnboardingDismissed(false);
      redirectTo(this.projectFullPath);
    },
    skipTour() {
      onboardingUtils.updateOnboardingDismissed(true);
      redirectTo(this.skipUrl);
    },
  },
};
</script>

<template>
  <div class="onboarding-welcome-page content col-lg-6 ml-auto mr-auto">
    <div class="text-center">
      <user-avatar-image
        :img-src="userAvatarUrl"
        :size="64"
        css-classes="ml-auto mr-auto"
        class="d-inline-block"
      />
      <h1>{{ __('Hello there') }}</h1>
      <p class="large">{{ __('Welcome to the Guided GitLab Tour') }}</p>
    </div>
    <p class="mt-4">
      {{
        __(
          'We created a short guided tour that will help you learn the basics of GitLab and how it will help you be better at your job. It should only take a couple of minutes. You will be guided by two types of helpers, best recognized by their color.',
        )
      }}
    </p>
    <div class="text-center mt-4 mb-4">
      <div
        id="js-popover-container"
        class="popover-container d-flex justify-content-around align-items-end mb-8"
      >
        <button ref="helpPopoverTrigger" type="button" class="btn-link btn-disabled"></button>
        <button
          ref="actionPopoverTrigger"
          type="button"
          class="btn-link btn-disabled mb-3"
        ></button>

        <help-content-popover
          v-if="helpPopover.target"
          :target="helpPopover.target"
          :help-content="helpPopover.content"
          placement="top"
          container="js-popover-container"
          show
        />

        <action-popover
          v-if="actionPopover.target"
          :target="actionPopover.target"
          :content="actionPopover.content"
          :css-classes="actionPopover.cssClasses"
          placement="top"
          container="js-popover-container"
          show-default
        />
      </div>
      <gl-link class="qa-start-tour-btn btn btn-success" @click="startTour">
        {{ __("Ok let's go") }}
      </gl-link>
      <p class="small mt-8">
        <gl-link class="qa-skip-tour-btn" @click="skipTour">
          {{ skipText }}
        </gl-link>
      </p>
      <p class="small ml-4 mr-4" v-html="helpText"></p>
    </div>
  </div>
</template>

<style scoped>
.popover-container {
  height: 140px;
}
p.large {
  font-size: 16px;
}
p.small {
  font-size: 12px;
}
.btn-success {
  width: 200px;
}
</style>
