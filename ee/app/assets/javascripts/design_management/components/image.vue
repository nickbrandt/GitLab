<script>
import _ from 'underscore';

export default {
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
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.resizeThrottled, false);
  },
  mounted() {
    this.onImgLoad();
    this.resizeThrottled = _.throttle(this.onImgLoad, 400);
    window.addEventListener('resize', this.resizeThrottled, false);
  },
  methods: {
    onImgLoad() {
      requestIdleCallback(this.calculateImgSize, { timeout: 1000 });
    },
    calculateImgSize() {
      const { contentImg } = this.$refs;

      if (!contentImg) return;

      this.$nextTick(() => {
        const naturalRatio = contentImg.naturalWidth / contentImg.naturalHeight;
        const visibleRatio = contentImg.width / contentImg.height;

        const position = {
          // Handling the case where img element takes more width than visible image thanks to object-fit: contain
          width:
            naturalRatio < visibleRatio
              ? contentImg.clientHeight * naturalRatio
              : contentImg.clientWidth,
          height: contentImg.clientHeight,
        };

        this.$emit('resize', position);
      });
    },
  },
};
</script>

<template>
  <div class="m-auto h-100 w-100 d-flex-center js-design-image">
    <img ref="contentImg" :src="image" :alt="name" class="img-fluid mh-100" @load="onImgLoad" />
  </div>
</template>
