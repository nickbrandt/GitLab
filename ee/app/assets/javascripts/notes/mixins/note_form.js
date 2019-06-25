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
    showResolveDiscussionToggle() {
      return (
        ((this.discussion && this.discussion.id && this.discussion.resolvable) || this.isDraft) &&
        this.withBatchComments
      );
    },
  },
  methods: {
    handleKeySubmit() {
      if (this.showBatchCommentsActions) {
        this.handleAddToReview();
      } else {
        this.handleUpdate();
      }
    },
    handleUpdate(shouldResolve) {
      const beforeSubmitDiscussionState = this.discussionResolved;
      this.isSubmitting = true;

      this.$emit(
        'handleFormUpdate',
        this.updatedNoteBody,
        this.$refs.editNoteForm,
        () => {
          this.isSubmitting = false;

          if (this.shouldToggleResolved(shouldResolve, beforeSubmitDiscussionState)) {
            this.resolveHandler(beforeSubmitDiscussionState);
          }
        },
        this.discussionResolved ? !this.isUnresolving : this.isResolving,
      );
    },
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
      // check if draft should resolve thread
      const shouldResolve =
        (this.discussionResolved && !this.isUnresolving) ||
        (!this.discussionResolved && this.isResolving);
      this.isSubmitting = true;

      this.$emit('handleFormUpdateAddToReview', this.updatedNoteBody, shouldResolve);
    },
  },
};
