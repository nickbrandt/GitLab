<script>
import { mapGetters } from 'vuex';
import parallelDiffTableRow from './parallel_diff_table_row.vue';
import parallelDiffCommentRow from './parallel_diff_comment_row.vue';

// eslint-disable-next-line import/order
import ParallelDraftCommentRow from 'ee/batch_comments/components/parallel_draft_comment_row.vue';

export default {
  components: {
    parallelDiffTableRow,
    parallelDiffCommentRow,
    ParallelDraftCommentRow,
  },
  props: {
    diffFile: {
      type: Object,
      required: true,
    },
    diffLines: {
      type: Array,
      required: true,
    },
  },
  computed: {
    ...mapGetters('diffs', ['commitId']),
    ...mapGetters('batchComments', ['shouldRenderParallelDraftRow', 'draftForLine']),
    diffLinesLength() {
      return this.diffLines.length;
    },
  },
  userColorScheme: window.gon.user_color_scheme,
};
</script>

<template>
  <div
    :class="$options.userColorScheme"
    :data-commit-id="commitId"
    class="code diff-wrap-lines js-syntax-highlight text-file"
  >
    <table>
      <tbody>
        <template v-for="(line, index) in diffLines">
          <parallel-diff-table-row
            :key="index"
            :file-hash="diffFile.file_hash"
            :context-lines-path="diffFile.context_lines_path"
            :line="line"
            :is-bottom="index + 1 === diffLinesLength"
          />
          <parallel-diff-comment-row
            :key="`dcr-${index}`"
            :line="line"
            :diff-file-hash="diffFile.file_hash"
            :line-index="index"
          />
          <parallel-draft-comment-row
            v-if="shouldRenderParallelDraftRow(diffFile.file_hash, line)"
            :key="`drafts-${index}`"
            :line="line"
            :diff-file-content-sha="diffFile.file_hash"
          />
        </template>
      </tbody>
    </table>
  </div>
</template>
