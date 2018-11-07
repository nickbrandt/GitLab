<script>
import { imagePath } from '~/lib/utils/common_utils';

export default {
  props: {
    title: {
      type: String,
      required: true,
    },
    summary: {
      type: String,
      required: true,
    },
    image: {
      type: String,
      required: true,
    },
  },
  computed: {
    imagePath() {
      return imagePath(this.image);
    },
  },
};
</script>
<template>
  <div class="row empty-state">
    <div class="col-12">
      <div class="svg-content">
        <img
          class="content-image"
          :src="imagePath"
        />
      </div>
    </div>
    <div class="col-12">
      <div class="text-content">
        <h4 class="content-title text-center">{{ title }}</h4>
        <p class="content-summary">{{ summary }}</p>
      </div>
    </div>
  </div>
</template>
