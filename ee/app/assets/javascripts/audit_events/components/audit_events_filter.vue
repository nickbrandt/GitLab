<script>
import { GlFilteredSearch } from '@gitlab/ui';
import { FILTER_TOKENS, AVAILABLE_TOKEN_TYPES } from '../constants';
import { availableTokensValidator } from '../validators';

export default {
  components: {
    GlFilteredSearch,
  },
  props: {
    value: {
      type: Array,
      required: false,
      default: () => [],
    },
    enabledTokenTypes: {
      type: Array,
      required: false,
      default: () => AVAILABLE_TOKEN_TYPES,
      validator: availableTokensValidator,
    },
    qaSelector: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  computed: {
    searchTerm() {
      return this.value.find(term => AVAILABLE_TOKEN_TYPES.includes(term.type));
    },
    enabledTokens() {
      return FILTER_TOKENS.filter(token => this.enabledTokenTypes.includes(token.type));
    },
    filterTokens() {
      // This limits the user to search by only one of the available tokens
      const { enabledTokens, searchTerm } = this;

      if (searchTerm?.type) {
        return enabledTokens.map(token => ({
          ...token,
          disabled: searchTerm.type !== token.type,
        }));
      }

      return enabledTokens;
    },
  },
  methods: {
    onSubmit() {
      this.$emit('submit');
    },
    onInput(val) {
      this.$emit('selected', val);
    },
  },
};
</script>

<template>
  <div
    class="input-group bg-white flex-grow-1"
    data-testid="audit-events-filter"
    :data-qa-selector="qaSelector"
  >
    <gl-filtered-search
      :value="value"
      :placeholder="__('Search')"
      :clear-button-title="__('Clear')"
      :close-button-title="__('Close')"
      :available-tokens="filterTokens"
      class="gl-h-32 w-100"
      @submit="onSubmit"
      @input="onInput"
    />
  </div>
</template>
