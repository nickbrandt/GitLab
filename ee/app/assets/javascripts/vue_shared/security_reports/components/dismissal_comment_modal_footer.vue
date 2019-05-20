<script>
import { GlButton } from '@gitlab/ui';
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
  },
};
</script>

<template>
  <div>
    <gl-button @click="$emit('cancel')">
      {{ __('Cancel') }}
    </gl-button>

    <loading-button
      :loading="isDismissingVulnerability"
      :disabled="isDismissingVulnerability"
      :label="s__('vulnerability|Add comment & dismiss')"
      container-class="btn btn-close"
      @click="$emit('dismissVulnerability')"
    />
  </div>
</template>
