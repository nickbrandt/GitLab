<script>
import { GlButton, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import DesignInput from './design_input.vue';

export default {
  components: {
    GlButton,
    GlLoadingIcon,
    DesignInput,
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
      this.$refs.fileUpload.$el.click();
    },
    onFileUploadChange(e) {
      this.$emit('upload', e.target.files);
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

    <design-input ref="fileUpload" @change="onFileUploadChange" />
  </div>
</template>
