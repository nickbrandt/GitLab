import { mapGetters, mapState } from 'vuex';

export default {
  props: {
    isDraft: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState({
      withBatchComments: state => state.batchComments && state.batchComments.withBatchComments,
    }),
    ...mapGetters('batchComments', ['hasDrafts']),
    showBatchCommentsActions() {
      return this.withBatchComments && this.noteId === '' && !this.discussion.for_commit;
    },
  },
  methods: {
    shouldBeResolved(resolveStatus) {
      if (this.withBatchComments) {
        return (
          (this.discussionResolved && !this.isUnresolving) ||
          (!this.discussionResolved && this.isResolving)
        );
      }

      return resolveStatus;
    },
    handleAddToReview() {
      // check if draft should resolve discussion
      const shouldResolve =
        (this.discussionResolved && !this.isUnresolving) ||
        (!this.discussionResolved && this.isResolving);
      this.isSubmitting = true;

      this.$emit('handleFormUpdateAddToReview', this.updatedNoteBody, shouldResolve);
    },
  },
};
