<script>
import { diffChars } from 'diff';
import InlineDiffTableRow from '~/diffs/components/inline_diff_view.vue';

export default {
  name: 'ReportItemDiff',
  components: { InlineDiffTableRow },
  props: {
    before: {
      type: String,
      required: true,
    },
    after: {
      type: String,
      required: true,
    },
  },
  computed: {
    diffData() {
      const opts = {
        ignoreWhitespace: false,
        newlineIsToken: true,
      };
      return diffChars(this.before, this.after, opts);
    },
  },
  methods: {
    changeClass(change) {
      if (change.added) {
        return 'line_content new';
      } else if (change.removed) {
        return 'line_content old';
      } else {
        return 'line_content';
      }
    },
  },
  userColorScheme: window.gon.user_color_scheme,
};
</script>

<template>
  <div class="file-holder">
    <table class="code" :class="$options.userColorScheme">
      <inline-diff-table-row
        v-for="(change, index) in diffData"
        :key="index"
        :file-hash="diff"
        :file-path="diff"
        :line="change"
        :is-bottom="index + 1 === diffData.length"
        :is-commented="false"
      />
    </table>
  </div>
</template>
