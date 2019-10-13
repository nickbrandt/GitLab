<script>
import MarkdownField from '~/vue_shared/components/markdown/field.vue';

export default {
  name: 'DesignReplyForm',
  components: {
    MarkdownField,
  },
  props: {
    markdownPreviewPath: {
      type: String,
      required: false,
      default: '',
    },
    value: {
      type: String,
      required: true,
    },
    isSaving: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    hasValue() {
      return this.value.trim().length > 0;
    },
  },
  mounted() {
    this.$refs.textarea.focus();
  },
  methods: {
    submitForm() {
      if (this.hasValue) this.$emit('submitForm');
    },
  },
};
</script>

<template>
  <form class="new-note common-note-form">
    <markdown-field
      :markdown-preview-path="markdownPreviewPath"
      :can-attach-file="false"
      :enable-autocomplete="false"
      markdown-docs-path="/help/user/markdown"
      class="bordered-box"
    >
      <textarea
        slot="textarea"
        ref="textarea"
        :value="value"
        class="note-textarea js-gfm-input js-autosize markdown-area"
        dir="auto"
        data-supports-quick-actions="false"
        data-qa-selector="note_textarea"
        :aria-label="__('Description')"
        :placeholder="__('Write a comment…')"
        @input="$emit('input', $event.target.value)"
        @keydown.meta.enter="submitForm"
        @keydown.ctrl.enter="submitForm"
        @keyup.esc.stop="$emit('cancelForm')"
      >
      </textarea>
    </markdown-field>
    <div class="note-form-actions">
      <button
        :disabled="!hasValue || isSaving"
        class="btn btn-success js-comment-button js-comment-submit-button"
        type="submit"
        data-track-event="click_button"
        data-qa-selector="save_comment_button"
        @click.prevent="$emit('submitForm')"
      >
        {{ __('Save comment') }}
      </button>
    </div>
  </form>
</template>
