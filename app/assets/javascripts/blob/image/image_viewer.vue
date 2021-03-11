<script>
export default {
  props: {
    imagePath: {
      type: String,
      required: true,
    },
    altText: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      imageWidth: null,
      imageHeight: null,
    };
  },
  methods: {
    onImageLoad() {
      this.imageWidth = this.$refs.image.naturalWidth;
      this.imageHeight = this.$refs.image.naturalHeight;
    },
  },
};
</script>

<template>
  <div class="file-content image_file">
    <img ref="image" :src="imagePath" :alt="altText" @load="onImageLoad" />
    <p v-if="imageWidth && imageHeight">
      <small>{{ imageWidth }}px (width) x {{ imageHeight }}px (height)</small>
    </p>
  </div>
</template>
