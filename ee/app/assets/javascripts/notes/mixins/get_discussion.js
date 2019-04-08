import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters(['getDiscussion']),
    discussion() {
      if (!this.note.isDraft) return {};

      return this.getDiscussion(this.note.discussion_id);
    },
  },
};
