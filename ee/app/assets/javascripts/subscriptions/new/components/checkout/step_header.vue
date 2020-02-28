<script>
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  props: {
    isFinished: {
      type: Boolean,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div class="d-flex">
    <icon
      v-show="isFinished"
      class="checkmark append-right-8"
      :size="18"
      :aria-label="title"
      name="check-circle"
    />
    <h5 class="prepend-top-0 append-bottom-default">{{ title }}</h5>
  </div>
</template>
