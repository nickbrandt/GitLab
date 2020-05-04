<script>
import MarkdownFieldMixin from '~/vue_shared/mixins/markdown_field_mixin';
import ViewerMixin from './mixins';
import { handleBlobRichViewer } from '~/blob/viewer';

export default {
  mixins: [ViewerMixin, MarkdownFieldMixin],
  mounted() {
    handleBlobRichViewer(this.$refs.content, this.type);
  },
};
</script>
<template>
  <div ref="content" v-html="content"></div>
</template>
