import { mapGetters } from 'vuex';
import { s__ } from '~/locale';

export default {
  computed: {
    ...mapGetters(['isDiscussionResolved']),
    resolvedStatusMessage() {
      let message;
      const discussionResolved = this.isDiscussionResolved(this.draft.discussion_id);
      const discussionToBeResolved = this.draft.resolve_discussion;

      if (discussionToBeResolved && discussionResolved && !this.$options.showStaysResolved) {
        return undefined;
      }

      if (discussionToBeResolved) {
        if (discussionResolved) {
          message = s__('MergeRequests|Discussion stays resolved.');
        } else {
          message = s__('MergeRequests|Discussion will be resolved.');
        }
      } else if (discussionResolved) {
        message = s__('MergeRequests|Discussion will be unresolved.');
      } else if (this.$options.showStaysResolved) {
        message = s__('MergeRequests|Discussion stays unresolved.');
      }

      return message;
    },
    componentClasses() {
      return this.draft.resolve_discussion
        ? 'is-resolving-discussion'
        : 'is-unresolving-discussion';
    },
  },
};
