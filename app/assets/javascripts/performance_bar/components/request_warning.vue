<script>
import { glEmojiTag } from '~/emoji';
import { GlPopover } from '@gitlab/ui';

export default {
  components: {
    GlPopover,
  },
  props: {
    htmlId: {
      type: String,
      required: true,
    },
    details: {
      type: Object,
      required: true,
    },
  },
  computed: {
    warnings() {
      const {
        details: { warnings },
      } = this;

      return warnings && warnings.length ? warnings : null;
    },
    warningMessage() {
      if (!this.warnings) {
        return '';
      }

      return this.warnings.join('\n');
    },
  },
  methods: {
    glEmojiTag,
  },
};
</script>
<template>
  <span v-if="warnings">
    <span :id="htmlId" v-html="glEmojiTag('warning')"></span>
    <gl-popover :target="htmlId" :content="warningMessage" triggers="hover focus" />
  </span>
</template>
