<script>
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  props: {
    isApproved: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <icon v-if="isApproved" name="mobile-issue-close" class="text-success" :size="16" />
  <div v-else class="square s16"></div>
</template>
