<script>
export default {
  inheritAttrs: false,
  props: {
    value: {
      type: [String, Number, Boolean],
      required: true,
    },
  },
  computed: {
    printValue() {
      if (typeof this.value === 'boolean') {
        return this.value ? 'true' : 'false';
      }

      return this.value;
    },
  },
};
</script>
<template>
  <span>{{ printValue }}</span>
</template>
