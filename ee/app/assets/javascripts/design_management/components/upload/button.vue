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
  <div>
    <gl-button :disabled="isSaving" variant="primary" @click="openFileUpload">
      {{ s__('DesignManagement|Add designs') }}
      <gl-loading-icon v-if="isSaving" inline class="ml-1" />
    </gl-button>
    <input
      ref="fileUpload"
      type="file"
      name="design_file"
      accept="image/*"
      class="hide"
      multiple
      @change="onFileUploadChange"
    />
  </div>
</template>
