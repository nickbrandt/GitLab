<script>
import { __ } from '~/locale';
import { GlLink, GlPopover } from '@gitlab/ui';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import { redirectTo } from '~/lib/utils/url_utility';
import { resetOnboardingLocalStorage, updateLocalStorage } from './../../utils';

export default {
  components: {
    GlLink,
    GlPopover,
    UserAvatarImage,
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
  },
  data() {
    return {
      helpText: __(
        "Don't worry, you can access this tour by clicking on the help icon in the top right corner and choose <strong>Learn GitLab</strong>.",
      ),
    };
  },
  mounted() {
    // workaround for appending a custom class to the bs popover which cannot be done via props
    // see https://github.com/bootstrap-vue/bootstrap-vue/issues/1983
    this.$root.$on('bv::popover::show', bvEventObj => {
      const {
        target: { dataset },
      } = bvEventObj;

      if (dataset.class) {
        bvEventObj.relatedTarget.classList.add(dataset.class);
      }
    });
  },
  methods: {
    startTour() {
      resetOnboardingLocalStorage();
      redirectTo(this.projectFullPath);
    },
    skipTour() {
      updateLocalStorage({ dismissed: true });
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
          'We created a short guided tour that will help you learn the basics of GitLab and how it will help you be better at your job. It should only take a couple of minutes. You willl be guided by two types of helpers, best recognized by their color.',
        )
      }}
    </p>
    <div class="text-center mt-4 mb-4">
      <div
        id="popover-container"
        class="popover-container d-flex justify-content-around align-items-end mb-8"
      >
        <button id="help-popover-trigger" type="button" class="btn-link btn-disabled"></button>
        <button
          id="action-popover-trigger"
          type="button"
          class="btn-link btn-disabled mb-3"
          data-class="blue"
        ></button>
        <gl-popover
          target="help-popover-trigger"
          placement="top"
          container="popover-container"
          show
        >
          <p class="mb-2">
            {{ __('White helpers give contextual information.') }}
          </p>
          <button disabled type="button" :aria-label="__('OK')" class="btn btn-xs popover-btn">
            {{ __('OK') }}
          </button>
        </gl-popover>
        <gl-popover
          target="action-popover-trigger"
          placement="top"
          container="popover-container"
          show
        >
          {{ __('Blue helpers indicate an action to be taken.') }}
        </gl-popover>
      </div>
      <gl-link class="btn btn-success" @click="startTour">
        {{ __("Ok let's go") }}
      </gl-link>
      <p class="small mt-8">
        <gl-link @click="skipTour">
          {{ __('Skip this for now') }}
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
.popover-btn[disabled] {
  background-color: #1b69b6 !important;
  border-color: #1b69b6 !important;
  color: white !important;
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
