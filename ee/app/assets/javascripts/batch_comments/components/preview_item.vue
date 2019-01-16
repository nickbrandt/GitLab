<script>
import { mapActions, mapGetters } from 'vuex';
import { sprintf, __ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import resolvedStatusMixin from '../mixins/resolved_status';

export default {
  components: {
    Icon,
  },
  mixins: [resolvedStatusMixin],
  props: {
    draft: {
      type: Object,
      required: true,
    },
    isLast: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapGetters('diffs', ['getDiffFileByHash']),
    ...mapGetters(['getDiscussion']),
    iconName() {
      return this.isDiffDiscussion || this.draft.line_code ? 'doc-text' : 'comment';
    },
    discussion() {
      return this.getDiscussion(this.draft.discussion_id);
    },
    isDiffDiscussion() {
      return this.discussion && this.discussion.diff_discussion;
    },
    titleText() {
      const file = this.discussion ? this.discussion.diff_file : this.draft;

      if (file) {
        return file.file_path;
      }

      return sprintf(__("%{authorsName}'s discussion"), {
        authorsName: this.discussion.notes.find(note => !note.system).author.name,
      });
    },
    linePosition() {
      const position = this.discussion ? this.discussion.position : this.draft.position;

      return position.new_line || position.old_line;
    },
    content() {
      const el = document.createElement('div');
      el.innerHTML = this.draft.note_html;

      return el.textContent;
    },
    showLinePosition() {
      return this.draft.file_hash || this.isDiffDiscussion;
    },
  },
  methods: {
    ...mapActions('batchComments', ['scrollToDraft']),
  },
  showStaysResolved: false,
};
</script>

<template>
  <button
    type="button"
    class="review-preview-item menu-item"
    :class="[
      componentClasses,
      {
        'is-last': isLast,
      },
    ]"
    @click="scrollToDraft(draft)"
  >
    <span class="review-preview-item-header">
      <icon class="append-right-8 flex-shrink-0" :name="iconName" />
      <span class="bold">
        <span class="review-preview-item-header-text block-truncated"> {{ titleText }} </span>
        <template v-if="showLinePosition">
          :{{ linePosition }}
        </template>
      </span>
    </span>
    <span class="review-preview-item-content">
      <p>{{ content }}</p>
    </span>
    <span
      v-if="draft.discussion_id && resolvedStatusMessage"
      class="review-preview-item-footer draft-note-resolution p-0"
    >
      <icon class="append-right-8" name="status_success" /> {{ resolvedStatusMessage }}
    </span>
  </button>
</template>
