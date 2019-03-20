<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlLoadingIcon,
  },
  props: {
    isSaving: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    openFileUpload() {
      this.$refs.fileUpload.click();
    },
    onFileUploadChange() {
      this.$emit('upload', this.$refs.fileUpload.files);
    },
  },
};
</script>

<template>
  <header class="row-content-block border-top-0 pt-2 pb-2 pl-0 pr-0 d-flex">
    <div class="ml-auto">
      <gl-button :disabled="isSaving" variant="primary" @click="openFileUpload">
        {{ s__('DesignManagement|Upload new designs') }}
        <gl-loading-icon v-if="isSaving" inline class="ml-1" />
      </gl-button>
      <input
        ref="fileUpload"
        type="file"
        name="design_file"
        accept="image/*"
        class="hide"
        @change="onFileUploadChange"
      />
    </div>
  </header>
</template>
