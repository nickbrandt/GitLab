<script>
export default {
  props: {
    rules: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <table class="table m-0">
    <thead class="thead-white text-nowrap">
      <slot name="thead"></slot>
    </thead>
    <tbody>
      <tr v-for="rule in rules" :key="rule.id">
        <slot :rule="rule" name="tr"></slot>
      </tr>
    </tbody>
  </table>
</template>
