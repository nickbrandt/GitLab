<script>
import { GlButton } from '@gitlab/ui';
import Stats from 'ee/stats';
import { s__ } from '~/locale';
import LoadingButton from '~/vue_shared/components/loading_button.vue';

export default {
  name: 'DismissalCommentModalFooter',
  components: {
    GlButton,
    LoadingButton,
  },
  props: {
    isDismissingVulnerability: {
      type: Boolean,
      required: false,
      default: false,
    },
    isDismissed: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    submitLabel() {
      return this.isDismissed
        ? s__('vulnerability|Add comment')
        : s__('vulnerability|Add comment & dismiss');
    },
  },
  methods: {
    addCommentAndDismiss() {
      Stats.trackEvent(document.body.dataset.page, 'click_add_comment_and_dismiss');
      this.$emit('addCommentAndDismiss');
    },
    addDismissalComment() {
      Stats.trackEvent(document.body.dataset.page, 'click_add_comment');
      this.$emit('addDismissalComment');
    },
    handleSubmit() {
      if (this.isDismissed) {
        this.addDismissalComment();
      } else {
        this.addCommentAndDismiss();
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-button class="js-cancel" @click="$emit('cancel')">
      {{ __('Cancel') }}
    </gl-button>

    <loading-button
      :loading="isDismissingVulnerability"
      :disabled="isDismissingVulnerability"
      :label="submitLabel"
      class="js-loading-button"
      container-class="btn btn-close"
      @click="handleSubmit"
    />
  </div>
</template>
