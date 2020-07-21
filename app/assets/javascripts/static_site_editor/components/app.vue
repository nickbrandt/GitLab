<script>
export default {
  props: {
    mergeRequestsIllustrationPath: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <router-view v-bind="$props" />
</template>
