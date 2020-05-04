<script>
import MarkdownFieldMixin from '~/vue_shared/mixins/markdown_field_mixin';

export default {
  mixins: [MarkdownFieldMixin],
  props: {
    description: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>
<template>
  <div class="snippet-description" data-qa-selector="snippet_description_field">
    <div class="md js-snippet-description" v-html="description"></div>
  </div>
</template>
