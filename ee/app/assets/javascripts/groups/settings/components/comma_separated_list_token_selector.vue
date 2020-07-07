<script>
import { GlTokenSelector } from '@gitlab/ui';

export default {
  name: 'CommaSeparatedListTokenSelector',
  hiddenInput: null,
  components: { GlTokenSelector },
  props: {
    hiddenInputId: {
      type: String,
      required: true,
    },
    ariaLabelledby: {
      type: String,
      required: true,
    },
    placeholder: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      selectedTokens: [],
    };
  },
  watch: {
    selectedTokens(newValue) {
      this.$options.hiddenInput.value = newValue.map(token => token.name).join(',');

      // Dispatch `input` event so form submit button becomes active
      this.$options.hiddenInput.dispatchEvent(
        new Event('input', {
          bubbles: true,
          cancelable: true,
        }),
      );
    },
  },
  mounted() {
    const hiddenInput = document.getElementById(this.hiddenInputId);
    this.$options.hiddenInput = hiddenInput;

    if (hiddenInput.value === '') {
      return;
    }

    this.selectedTokens = hiddenInput.value.split(/,\s*/).map((token, index) => ({
      id: index,
      name: token,
    }));
  },
  methods: {
    handleEnter(event) {
      // Prevent form from submitting when adding a token
      if (event.target.value !== '') {
        event.preventDefault();
      }
    },
  },
};
</script>

<template>
  <gl-token-selector
    v-model="selectedTokens"
    container-class="gl-h-auto!"
    allow-user-defined-tokens
    hide-dropdown-with-no-items
    :aria-labelledby="ariaLabelledby"
    :placeholder="placeholder"
    @keydown.enter="handleEnter"
  >
    <template #user-defined-token-content="{ inputText }">
      <slot name="user-defined-token-content" :input-text="inputText"></slot>
    </template>
  </gl-token-selector>
</template>
