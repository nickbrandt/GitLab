<script>
import { n__ } from '~/locale';

export default {
  props: {
    type: {
      type: String,
      required: true,
    },
    /**
     * With default null we will render a "-" in the last column as opposed to a numeric value
     */
    value: {
      type: Number,
      required: false,
      default: null,
    },
    label: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    isNumericValue() {
      return this.value !== null && !Number.isNaN(Number(this.value));
    },
    unit() {
      return this.type === 'days_to_merge'
        ? n__('day', 'days', this.value)
        : n__('Time|hr', 'Time|hrs', this.value);
    },
  },
};
</script>
<template>
  <div class="metric-col">
    <span class="time">
      <template v-if="isNumericValue">
        {{ value }}
        <span> {{ unit }} </span>
      </template>
      <template v-else>
        &ndash;
      </template>
    </span>
    <span v-if="label" class="d-flex d-md-none text-secondary metric-label">{{ label }}</span>
  </div>
</template>
