export default {
  computed: {
    isDraft() {
      return this.note.isDraft;
    },
    canResolve() {
      return (
        this.note.current_user.can_resolve ||
        (this.note.isDraft && this.note.discussion_id !== null)
      );
    },
  },
};
