<script>
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'DesignOverlay',
  components: {
    Icon,
  },
  props: {
    position: {
      type: Object,
      required: true,
    },
    notes: {
      type: Array,
      required: false,
      default: () => [],
    },
    currentCommentForm: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    overlayDimensions() {
      return {
        width: `${this.position.width}px`,
        height: `${this.position.height}px`,
        left: `calc(50% - ${this.position.width / 2}px)`,
        top: `calc(50% - ${this.position.height / 2}px)`,
      };
    },
  },
  methods: {
    clickedImage(x, y) {
      this.$emit('openCommentForm', { x, y });
    },
    getNotePosition(data) {
      const { x, y, width, height } = data;
      const widthRatio = this.position.width / width;
      const heightRatio = this.position.height / height;
      return {
        left: `${Math.round(x * widthRatio)}px`,
        top: `${Math.round(y * heightRatio)}px`,
      };
    },
  },
};
</script>

<template>
  <div class="position-absolute image-diff-overlay frame" :style="overlayDimensions">
    <button
      type="button"
      class="btn-transparent position-absolute image-diff-overlay-add-comment w-100 h-100 js-add-image-diff-note-button"
      data-qa-selector="design_image_button"
      @click="clickedImage($event.offsetX, $event.offsetY)"
    ></button>
    <button
      v-for="(note, index) in notes"
      :key="note.id"
      :style="getNotePosition(note.position)"
      class="js-image-badge badge badge-pill position-absolute"
      type="button"
    >
      {{ index + 1 }}
    </button>
    <button
      v-if="currentCommentForm"
      :style="getNotePosition(currentCommentForm)"
      :aria-label="__('Comment form position')"
      class="btn-transparent comment-indicator position-absolute"
      type="button"
    >
      <icon name="image-comment-dark" />
    </button>
  </div>
</template>
