<script>
import { GlFilteredSearch } from '@gitlab/ui';
import { FILTER_TOKENS, AVAILABLE_TOKEN_TYPES } from '../constants';
import { availableTokensValidator } from '../validators';

export default {
  components: {
    GlFilteredSearch,
  },
  props: {
    defaultSelectedToken: {
      type: Object,
      required: false,
      default: null,
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
  data() {
    return {
      searchTerms: [],
    };
  },
  computed: {
    searchTerm() {
      return this.searchTerms.find(term => AVAILABLE_TOKEN_TYPES.includes(term.type));
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
    searchValue() {
      const { searchTerm } = this;
      return {
        id: searchTerm?.value?.data,
        type: searchTerm?.type,
      };
    },
  },
  created() {
    const { defaultSelectedToken } = this;
    if (defaultSelectedToken) {
      const { id, type } = defaultSelectedToken;
      this.searchTerms = [{ type, value: { data: id, operator: '=' } }];
    }
  },
  methods: {
    onSubmit() {
      this.$emit('selected', this.searchValue);
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
      v-model="searchTerms"
      :placeholder="__('Search')"
      :clear-button-title="__('Clear')"
      :close-button-title="__('Close')"
      :available-tokens="filterTokens"
      class="gl-h-32 w-100"
      @submit="onSubmit"
    />
  </div>
</template>
