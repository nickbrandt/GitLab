<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { sprintf, s__ } from '~/locale';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import { GlModal, GlModalDirective } from '@gitlab-org/gitlab-ui';
import PublishButton from './publish_button.vue';

export default {
  components: {
    PublishButton,
    LoadingButton,
    GlModal,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  computed: {
    ...mapState('batchComments', ['isDiscarding']),
    ...mapGetters('batchComments', ['draftsCount']),
  },
  methods: {
    ...mapActions('batchComments', ['discardReview']),
  },
  modalId: 'discard-draft-review',
  text: sprintf(
    s__(
      `BatchComments|You're about to discard your review which will delete all of your pending comments.
      The deleted comments %{strong_start}cannot%{strong_end} be restored.`,
    ),
    {
      strong_start: '<strong>',
      strong_end: '</strong>',
    },
    false,
  ),
};
</script>
<template>
  <div v-show="draftsCount > 0">
    <nav class="review-bar-component">
      <p class="review-bar-content">
        <publish-button />
        <loading-button
          v-gl-modal="$options.modalId"
          :loading="isDiscarding"
          :label="__('Discard review')"
        />
      </p>
    </nav>
    <gl-modal
      :title="s__('BatchComments|Discard review?')"
      :ok-title="s__('BatchComments|Delete all pending comments')"
      :modal-id="$options.modalId"
      title-tag="h4"
      ok-variant="danger"
      @ok="discardReview"
    >
      <p v-html="$options.text">
      </p>
    </gl-modal>
  </div>
</template>
