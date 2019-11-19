<script>
import { ApolloMutation } from 'vue-apollo';
import { s__ } from '~/locale';
import createFlash from '~/flash';
import ReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import allVersionsMixin from '../../mixins/all_versions';
import createNoteMutation from '../../graphql/mutations/createNote.mutation.graphql';
import getDesignQuery from '../../graphql/queries/getDesign.query.graphql';
import DesignNote from './design_note.vue';
import DesignReplyForm from './design_reply_form.vue';
import { extractCurrentDiscussion, extractDesign } from '../../utils/design_management_utils';

export default {
  components: {
    ApolloMutation,
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
    };
  },
  computed: {
    mutationPayload() {
      return {
        noteableId: this.noteableId,
        body: this.discussionComment,
        discussionId: this.discussion.id,
      };
    },
    designVariables() {
      return {
        fullPath: this.projectPath,
        iid: this.issueIid,
        filenames: [this.$route.params.id],
        atVersion: this.designsVersion,
      };
    },
  },
  methods: {
    addDiscussionComment(
      store,
      {
        data: { createNote },
      },
    ) {
      const data = store.readQuery({
        query: getDesignQuery,
        variables: this.designVariables,
      });

      const design = extractDesign(data);
      const currentDiscussion = extractCurrentDiscussion(design.discussions, this.discussion.id);
      currentDiscussion.node.notes.edges = [
        ...currentDiscussion.node.notes.edges,
        {
          __typename: 'NoteEdge',
          node: createNote.note,
        },
      ];

      design.notesCount += 1;
      store.writeQuery({
        query: getDesignQuery,
        variables: this.designVariables,
        data: {
          ...data,
          design: {
            ...design,
          },
        },
      });
    },
    onDone() {
      this.discussionComment = '';
      this.hideForm();
    },
    onError(e) {
      createFlash(s__('DesignManagement|Could not add a new comment. Please try again'));
      throw e;
    },
    hideForm() {
      this.isFormRendered = false;
    },
    showForm() {
      this.isFormRendered = true;
    },
  },
  createNoteMutation,
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
        <apollo-mutation
          v-else
          v-slot="{ mutate, loading, error }"
          :mutation="$options.createNoteMutation"
          :variables="{
            input: mutationPayload,
          }"
          :update="addDiscussionComment"
          @done="onDone"
          @error="onError"
        >
          <design-reply-form
            v-model="discussionComment"
            :is-saving="loading"
            :markdown-preview-path="markdownPreviewPath"
            @submitForm="mutate"
            @cancelForm="hideForm"
          />
        </apollo-mutation>
      </div>
    </div>
  </div>
</template>
