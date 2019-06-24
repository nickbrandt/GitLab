<script>
import { GlPopover } from '@gitlab/ui';
import eventHub from '../event_hub';

export default {
  name: 'ActionPopover',
  components: {
    GlPopover,
  },
  props: {
    target: {
      type: HTMLElement,
      required: true,
    },
    content: {
      type: String,
      required: false,
      default: '',
    },
    placement: {
      type: String,
      required: false,
      default: 'top',
    },
    showDefault: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      showPopover: this.showDefault,
    };
  },
  mounted() {
    eventHub.$on('onboardingHelper.showActionPopover', () => this.toggleShowPopover(true));
    eventHub.$on('onboardingHelper.hideActionPopover', () => this.toggleShowPopover(false));
    eventHub.$on('onboardingHelper.destroyActionPopover', () =>
      this.$root.$off('bv::popover::show'),
    );
  },
  beforeDestroy() {
    eventHub.$off('onboardingHelper.showActionPopover');
    eventHub.$off('onboardingHelper.hideActionPopover');
    eventHub.$off('onboardingHelper.destroyActionPopover');
  },
  methods: {
    toggleShowPopover(show) {
      this.showPopover = show;
    },
  },
};
</script>

<template>
  <gl-popover
    v-bind="$attrs"
    :target="target"
    boundary="viewport"
    :placement="placement"
    :show="showPopover"
    :css-classes="['blue', 'onboarding-popover']"
  >
    <div v-html="content"></div>
  </gl-popover>
</template>
