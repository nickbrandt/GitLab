<script>
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    GlLoadingIcon,
  },
  props: {
    image: {
      type: String,
      required: false,
      default: '',
    },
    name: {
      type: String,
      required: false,
      default: '',
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <div class="d-flex align-items-center h-100 w-100 p-3 overflow-hidden js-design-image">
    <gl-loading-icon v-if="isLoading" class="ml-auto mr-auto" size="md" color="light" />
    <img v-else :src="image" :alt="name" class="ml-auto mr-auto img-fluid mh-100" />
  </div>
</template>
