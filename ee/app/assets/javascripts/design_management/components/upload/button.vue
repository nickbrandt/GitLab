<script>
import { GlButton, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    <gl-button
      v-gl-tooltip.hover
      :title="
        s__(
          'DesignManagement|Adding a design with the same filename replaces the file in a new version.',
        )
      "
      :disabled="isSaving"
      variant="success"
      @click="openFileUpload"
    >
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
