<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { NodeViewWrapper, nodeViewProps } from '@tiptap/vue-2';

export default {
  name: 'ImageWrapper',
  components: {
    NodeViewWrapper,
    GlLoadingIcon,
  },
  props: nodeViewProps,
};
</script>
<template>
  <node-view-wrapper class="content-editor-image">
    <div class="gl-relative">
      <img
        class="gl-w-full gl-h-auto"
        :class="{ 'gl-opacity-5': node.attrs.uploading }"
        :src="node.attrs.encodedSrc"
      />
      <gl-loading-icon v-if="node.attrs.uploading" class="gl-absolute gl-top-half" />
    </div>
  </node-view-wrapper>
</template>
<style>
.content-editor-image .gl-spinner-container {
  left: 50%;
}
</style>
