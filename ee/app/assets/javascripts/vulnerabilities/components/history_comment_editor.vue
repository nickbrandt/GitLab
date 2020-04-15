<script>
import { GlFormTextarea, GlNewButton, GlLoadingIcon } from '@gitlab/ui';

export default {
  components: { GlFormTextarea, GlNewButton, GlLoadingIcon },
  props: {
    initialComment: {
      type: String,
      required: false,
      default: '',
    },
    isSaving: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      comment: this.initialComment.trim(),
    };
  },
  computed: {
    isSaveButtonDisabled() {
      return this.isSaving || !this.trimmedComment.length;
    },
    trimmedComment() {
      return this.comment.trim();
    },
  },
};
</script>

<template>
  <div>
    <gl-form-textarea
      v-model="comment"
      :placeholder="s__('vulnerability|Add a comment')"
      :disabled="isSaving"
      autofocus
    />
    <div class="mt-3">
      <gl-new-button
        ref="saveButton"
        variant="success"
        :disabled="isSaveButtonDisabled"
        @click="$emit('onSave', trimmedComment)"
      >
        <gl-loading-icon v-if="isSaving" class="mr-1" />
        {{ __('Save comment') }}
      </gl-new-button>
      <gl-new-button
        ref="cancelButton"
        class="ml-1"
        :disabled="isSaving"
        @click="$emit('onCancel')"
      >
        {{ __('Cancel') }}
      </gl-new-button>
    </div>
  </div>
</template>
