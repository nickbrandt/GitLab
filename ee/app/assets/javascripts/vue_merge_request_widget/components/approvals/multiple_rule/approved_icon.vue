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
  <icon name="check-circle" class="text-success" :size="16" v-if="isApproved" />
  <div class="svg-wrapper s16" v-else></div>
</template>
