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
      class="checkmark gl-mr-3"
      :size="18"
      :aria-label="title"
      name="check-circle"
    />
    <h5 class="gl-mt-0 append-bottom-default">{{ title }}</h5>
  </div>
</template>
