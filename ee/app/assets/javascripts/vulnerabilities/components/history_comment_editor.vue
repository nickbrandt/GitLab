<script>
import { sanitize } from 'dompurify';
import { GlFormTextarea, GlButton, GlLoadingIcon } from '@gitlab/ui';

export default {
  components: { GlFormTextarea, GlButton, GlLoadingIcon },
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
      return this.isSaving || !this.sanitizedComment.length;
    },
    sanitizedComment() {
      return sanitize(this.comment.trim());
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
      <gl-button
        ref="saveButton"
        variant="success"
        :disabled="isSaveButtonDisabled"
        @click="$emit('onSave', sanitizedComment)"
      >
        <gl-loading-icon v-if="isSaving" class="mr-1" />
        {{ __('Save comment') }}
      </gl-button>
      <gl-button ref="cancelButton" class="ml-1" :disabled="isSaving" @click="$emit('onCancel')">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </div>
</template>
