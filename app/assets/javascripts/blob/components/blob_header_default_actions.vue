<script>
import { GlButton, GlButtonGroup, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { BTN_COPY_CONTENTS_TITLE, BTN_DOWNLOAD_TITLE, BTN_RAW_TITLE } from './constants';

export default {
  components: {
    GlIcon,
    GlButtonGroup,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    blob: {
      type: Object,
      required: true,
    },
  },
  computed: {
    copyBtnTitle() {
      return __(BTN_COPY_CONTENTS_TITLE);
    },
    rawBtnTitle() {
      return __(BTN_RAW_TITLE);
    },
    downloadBtnTitle() {
      return __(BTN_DOWNLOAD_TITLE);
    },
    rawUrl() {
      return this.blob.rawPath;
    },
    downloadUrl() {
      return `${this.blob.rawPath}?inline=false`;
    },
  },
  methods: {
    requestCopyContents() {
      this.$emit('copy');
    },
  },
};
</script>
<template>
  <gl-button-group>
    <gl-button
      v-gl-tooltip.hover
      :aria-label="copyBtnTitle"
      :title="copyBtnTitle"
      @click="requestCopyContents"
    >
      <gl-icon name="copy-to-clipboard" :size="14" />
    </gl-button>
    <gl-button
      v-gl-tooltip.hover
      :aria-label="rawBtnTitle"
      :title="rawBtnTitle"
      :href="rawUrl"
      rel="noopener noreferrer"
      target="_blank"
    >
      <gl-icon name="doc-code" :size="14" />
    </gl-button>
    <gl-button
      v-gl-tooltip.hover
      :aria-label="downloadBtnTitle"
      :title="downloadBtnTitle"
      :href="downloadUrl"
      rel="noopener noreferrer"
      target="_blank"
    >
      <gl-icon name="download" :size="14" />
    </gl-button>
  </gl-button-group>
</template>
