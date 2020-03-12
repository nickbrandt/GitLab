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
    scale: {
      type: Number,
      required: false,
      default: 1,
    },
  },
  data() {
    return {
      baseImageSize: null,
      imageStyle: null,
    };
  },
  watch: {
    scale(val) {
      this.zoom(val);
    },
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.resizeThrottled, false);
  },
  mounted() {
    this.onImgLoad();

    this.resizeThrottled = _.throttle(() => {
      // NOTE: if imageStyle is set, then baseImageSize
      // won't change due to resize. We must still emit a
      // `resize` event so that the parent can handle
      // resizes appropriately (e.g. for design_overlay)
      this.setBaseImageSize();
    }, 400);
    window.addEventListener('resize', this.resizeThrottled, false);
  },
  methods: {
    onImgLoad() {
      requestIdleCallback(this.setBaseImageSize, { timeout: 1000 });
    },
    setBaseImageSize() {
      const { contentImg } = this.$refs;
      if (!contentImg || contentImg.offsetHeight === 0 || contentImg.offsetWidth === 0) return;

      this.baseImageSize = {
        height: contentImg.offsetHeight,
        width: contentImg.offsetWidth,
      };
      this.onResize({ width: this.baseImageSize.width, height: this.baseImageSize.height });
    },
    onResize({ width, height }) {
      this.$emit('resize', { width, height });
    },
    zoom(amount) {
      if (amount === 1) {
        this.imageStyle = null;
        this.$nextTick(() => {
          this.setBaseImageSize();
        });
        return;
      }
      const width = this.baseImageSize.width * amount;
      const height = this.baseImageSize.height * amount;

      this.imageStyle = {
        width: `${width}px`,
        height: `${height}px`,
      };

      this.onResize({ width, height });
    },
  },
};
</script>

<template>
  <div class="m-auto js-design-image">
    <img
      ref="contentImg"
      class="mh-100"
      :src="image"
      :alt="name"
      :style="imageStyle"
      :class="{ 'img-fluid': !imageStyle }"
      @load="onImgLoad"
    />
  </div>
</template>
