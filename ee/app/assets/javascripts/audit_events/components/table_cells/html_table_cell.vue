<script>
import sanitize from 'sanitize-html';

const ALLOWED_TAGS = ['strong'];

export default {
  props: {
    html: {
      type: String,
      required: true,
    },
  },
  computed: {
    sanitisedHtml() {
      return sanitize(this.html, { allowedTags: ALLOWED_TAGS });
    },
  },
};
</script>

<template>
  <span v-html="sanitisedHtml"></span>
</template>
