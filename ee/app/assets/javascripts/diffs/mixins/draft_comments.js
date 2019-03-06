import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters('batchComments', [
      'shouldRenderDraftRow',
      'shouldRenderParallelDraftRow',
      'draftForLine',
    ]),
  },
};
