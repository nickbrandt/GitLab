import { mapGetters } from 'vuex';
import { s__ } from '~/locale';

export default {
  props: {
    discussionId: {
      type: String,
      required: false,
      default: null,
    },
    resolveDiscussion: {
      type: Boolean,
      required: false,
      default: false,
    },
    isDraft: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapGetters(['isDiscussionResolved']),
    resolvedStatusMessage() {
      let message;
      const discussionResolved = this.isDiscussionResolved(
        this.draft ? this.draft.discussion_id : this.discussionId,
      );
      const discussionToBeResolved = this.draft
        ? this.draft.resolve_discussion
        : this.resolveDiscussion;

      if (discussionToBeResolved && discussionResolved && !this.$options.showStaysResolved) {
        return undefined;
      }

      if (discussionToBeResolved) {
        if (discussionResolved) {
          message = s__('MergeRequests|Discussion stays resolved');
        } else {
          message = s__('MergeRequests|Discussion will be resolved');
        }
      } else if (discussionResolved) {
        message = s__('MergeRequests|Discussion will be unresolved');
      } else if (this.$options.showStaysResolved) {
        message = s__('MergeRequests|Discussion stays unresolved');
      }

      return message;
    },
    componentClasses() {
      return this.resolveDiscussion ? 'is-resolving-discussion' : 'is-unresolving-discussion';
    },
  },
};
