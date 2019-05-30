<script>
import { GlButton } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import {
  DANGER,
  DANGER_ALERT_CLASS,
  DANGER_TEXT_CLASS,
  WARNING,
  WARNING_ALERT_CLASS,
  WARNING_TEXT_CLASS,
} from './constants';

export default {
  name: 'DependencyListAlert',
  components: {
    GlButton,
    Icon,
  },
  props: {
    type: {
      type: String,
      required: false,
      default: DANGER,
      validator: value => [WARNING, DANGER].includes(value),
    },
    headerText: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    textClass() {
      return (
        {
          [WARNING]: WARNING_TEXT_CLASS,
          [DANGER]: DANGER_TEXT_CLASS,
        }[this.type] || ''
      );
    },
    alertClass() {
      return (
        {
          [WARNING]: WARNING_ALERT_CLASS,
          [DANGER]: DANGER_ALERT_CLASS,
        }[this.type] || ''
      );
    },
  },
};
</script>

<template>
  <div :class="[alertClass, textClass]">
    <gl-button
      :class="['btn-blank float-right mr-1 mt-1 js-close', textClass]"
      :aria-label="__('Close')"
      @click="$emit('close')"
    >
      <icon name="close" aria-hidden="true" />
    </gl-button>
    <h4 v-if="headerText" :class="textClass">{{ headerText }}</h4>
    <slot></slot>
  </div>
</template>
