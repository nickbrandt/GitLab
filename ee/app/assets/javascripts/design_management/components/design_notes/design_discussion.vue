<script>
import { s__ } from '~/locale';
import createFlash from '~/flash';
import ReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import allVersionsMixin from '../../mixins/all_versions';
import createNoteMutation from '../../graphql/mutations/createNote.mutation.graphql';
import getDesignQuery from '../../graphql/queries/getDesign.query.graphql';
import DesignNote from './design_note.vue';
import DesignReplyForm from './design_reply_form.vue';
import { extractCurrentDiscussion } from '../../utils/design_management_utils';

export default {
  components: {
    DesignNote,
    ReplyPlaceholder,
    DesignReplyForm,
  },
  mixins: [allVersionsMixin],
  props: {
    discussion: {
      type: Object,
      required: true,
    },
    noteableId: {
      type: String,
      required: true,
    },
    designId: {
      type: String,
      required: true,
    },
    discussionIndex: {
      type: Number,
      required: true,
    },
    markdownPreviewPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      discussionComment: '',
      isFormRendered: false,
      isNoteSaving: false,
    };
  },
  computed: {
    isSubmitButtonDisabled() {
      return this.discussionComment.trim().length === 0;
    },
  },
  methods: {
    addDiscussionComment() {
      this.isNoteSaving = true;
      return this.$apollo
        .mutate({
          mutation: createNoteMutation,
          variables: {
            input: {
              noteableId: this.noteableId,
              body: this.discussionComment,
              discussionId: this.discussion.id,
            },
          },
          update: (store, { data: { createNote } }) => {
            const data = store.readQuery({
              query: getDesignQuery,
              variables: {
                id: this.designId,
                version: this.designsVersion,
              },
            });
            const currentDiscussion = extractCurrentDiscussion(
              data.design.discussions,
              this.discussion.id,
            );
            currentDiscussion.node.notes.edges.push({
              __typename: 'NoteEdge',
              node: createNote.note,
            });
            data.design.notesCount += 1;
            store.writeQuery({ query: getDesignQuery, data });
          },
        })
        .then(() => {
          this.discussionComment = '';
          this.hideForm();
        })
        .catch(e => {
          createFlash(s__('DesignManagement|Could not add a new comment. Please try again'));
          throw e;
        })
        .finally(() => {
          this.isNoteSaving = false;
        });
    },
    hideForm() {
      this.isFormRendered = false;
    },
    showForm() {
      this.isFormRendered = true;
    },
  },
};
</script>

<template>
  <div class="design-discussion-wrapper">
    <div class="badge badge-pill" type="button">{{ discussionIndex }}</div>
    <div
      class="design-discussion bordered-box position-relative"
      data-qa-selector="design_discussion_content"
    >
      <design-note v-for="note in discussion.notes" :key="note.id" :note="note" />
      <div class="reply-wrapper">
        <reply-placeholder
          v-if="!isFormRendered"
          class="qa-discussion-reply"
          :button-text="__('Reply...')"
          @onClick="showForm"
        />
        <design-reply-form
          v-else
          v-model="discussionComment"
          :is-saving="isNoteSaving"
          :markdown-preview-path="markdownPreviewPath"
          @submitForm="addDiscussionComment"
          @cancelForm="hideForm"
        />
      </div>
    </div>
  </div>
</template>
