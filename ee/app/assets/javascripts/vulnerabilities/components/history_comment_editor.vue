<script>
<<<<<<< HEAD
import { sanitize } from 'dompurify';
import { GlFormTextarea, GlButton, GlLoadingIcon } from '@gitlab/ui';
=======
import { GlFormTextarea, GlButton } from '@gitlab/ui';
>>>>>>> origin/master

export default {
  components: { GlFormTextarea, GlButton },
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
<<<<<<< HEAD
        @click="$emit('onSave', sanitizedComment)"
=======
        :loading="isSaving"
        @click="$emit('onSave', trimmedComment)"
>>>>>>> origin/master
      >
        {{ __('Save comment') }}
      </gl-button>
      <gl-button ref="cancelButton" class="ml-1" :disabled="isSaving" @click="$emit('onCancel')">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </div>
</template>
