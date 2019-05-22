<script>
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
  data() {
    return {
      closed: false,
    };
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
  methods: {
    close() {
      this.closed = true;
    },
  },
};
</script>

<template>
  <div v-if="!closed" :class="[alertClass, textClass]">
    <button
      class="btn-blank float-right mr-1 mt-1 js-close"
      :class="textClass"
      type="button"
      :aria-label="__('Close')"
      @click="close"
    >
      <icon name="close" aria-hidden="true" />
    </button>
    <h4 v-if="headerText" :class="textClass">{{ headerText }}</h4>
    <slot></slot>
  </div>
</template>
