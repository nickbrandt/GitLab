<script>
import { GlFriendlyWrap, GlLink } from '@gitlab/ui';

export default {
  name: 'ReportItemFileLocation',
  components: {
    GlFriendlyWrap,
    GlLink,
  },
  props: {
    path: {
      type: String,
      required: true
    },
    lineStart: {
      type: Number,
      required: true
    },
    lineEnd: {
      type: Number,
      default: null,
      required: false
    },
    gitRef: {
      type: String,
      default: null,
      required: false
    },
  },
  computed: {
    linkToFile() {
      return "some_link";
    },
    fileWithLines() {
      let lineDesc = '';
      if (this.lineEnd !== null) {
        lineDesc = `${this.lineStart}-${this.lineEnd}`;
      } else {
        lineDesc = `${this.lineStart}`;
      }
      return `${this.path}:${lineDesc}`;
    },
  },
};
</script>

<template>
  <div>
    <gl-link
      ref="fileLink"
      :href="linkToFile"
      target="_blank"
    >
      <gl-friendly-wrap :text="fileWithLines" />
    </gl-link>
  </div>
</template>
