<script>
import { s__ } from '~/locale';

export default {
  props: {
    step: {
      type: Number,
      required: true,
    },
  },
  methods: {
    classObject(stepNumber) {
      return {
        phase: true,
        bold: true,
        center: true,
        finished: this.step > stepNumber,
        current: this.step === stepNumber,
      };
    },
  },
  i18n: {
    yourProfile: s__('Checkout|1. Your profile'),
    checkout: s__('Checkout|2. Checkout'),
    yourGroup: s__('Checkout|3. Your GitLab group'),
  },
};
</script>
<template>
  <div class="bar d-flex">
    <div v-for="(value, name, index) in $options.i18n" :key="name" :class="classObject(index + 1)">
      {{ value }}
    </div>
  </div>
</template>
