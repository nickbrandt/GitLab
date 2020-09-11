<script>
import { dynI8n } from '../dynamic_i8n';

export default {
  name: 'ReportItemText',
  props: {
    value: {
      type: Array,
      required: true,
    },
  },
  computed: {
    valueText() {
      return dynI8n(this.value);
    },
  },
};
</script>

<template>
  <div>{{ valueText }}</div>
</template>
