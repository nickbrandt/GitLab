<script>
import UploadButton from './button.vue';

export default {
  components: {
    UploadButton,
  },
  props: {
    isSaving: {
      type: Boolean,
      required: true,
    },
    canUploadDesign: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    onFileUploadChange(files) {
      this.$emit('upload', files);
    },
  },
};
</script>

<template>
  <header class="row-content-block border-top-0 p-2 d-flex">
    <div>
      <upload-button
        v-if="canUploadDesign"
        :is-saving="isSaving"
        :is-inverted="true"
        @upload="onFileUploadChange"
      />
    </div>
  </header>
</template>
