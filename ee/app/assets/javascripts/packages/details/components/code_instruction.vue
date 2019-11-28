<script>
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  name: 'CodeInstruction',
  components: {
    ClipboardButton,
  },
  props: {
    instruction: {
      type: String,
      required: true,
    },
    copyText: {
      type: String,
      required: true,
    },
    multiline: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div v-if="!multiline" class="input-group append-bottom-10">
    <input :value="instruction" type="text" class="form-control monospace" readonly />
    <span class="input-group-append">
      <clipboard-button :text="instruction" :title="copyText" class="input-group-text" />
    </span>
  </div>

  <div v-else>
    <pre>{{ instruction }}</pre>
  </div>
</template>
