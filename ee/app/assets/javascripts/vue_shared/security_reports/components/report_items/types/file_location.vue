<script>
import { GlFriendlyWrap, GlLink } from '@gitlab/ui';
import { getBaseURL } from '~/lib/utils/url_utility';

export default {
  name: 'ReportItemFileLocation',
  components: {
    GlFriendlyWrap,
    GlLink,
  },
  props: {
    vuln: {
      type: Object,
      required: true,
    },
    file_name: {
      type: String,
      required: true,
    },
    line_start: {
      type: Number,
      required: true,
    },
    line_end: {
      type: Number,
      default: null,
      required: false,
    },
    git_ref: {
      type: String,
      default: null,
      required: false,
    },
  },
  computed: {
    linkToFile() {
      const base = getBaseURL();
      const { project } = this.vuln;
      return `${base}//${project.full_path}/-/tree/master/${this.file_name}${this.linesFragment}`;
    },
    linesFragment() {
      let res = `#L${this.line_start}`;
      if (this.line_end !== null) {
        res += `-${this.line_end}`;
      }
      return res;
    },
    fileWithLines() {
      let lineDesc = '';
      if (this.line_end !== null) {
        lineDesc = `${this.line_start}-${this.line_end}`;
      } else {
        lineDesc = `${this.line_start}`;
      }
      return `${this.file_name}:${lineDesc}`;
    },
  },
};
</script>

<template>
  <div>
    <gl-link ref="fileLink" :href="linkToFile" target="_blank">
      <gl-friendly-wrap :text="fileWithLines" />
    </gl-link>
  </div>
</template>
