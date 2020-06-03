<script>
import { GlFilteredSearch } from '@gitlab/ui';
import { queryToObject } from '~/lib/utils/url_utility';
import { FILTER_TOKENS, AVAILABLE_TOKEN_TYPES } from '../constants';
import { availableTokensValidator } from '../validators';

export default {
  components: {
    GlFilteredSearch,
  },
  props: {
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
    id() {
      return this.searchTerm?.value?.data;
    },
    type() {
      return this.searchTerm?.type;
    },
  },
  created() {
    this.setSearchTermsFromQuery();
  },
  methods: {
    // The form logic here will be removed once all the audit
    // components are migrated into a single Vue application.
    // https://gitlab.com/gitlab-org/gitlab/-/issues/215363
    getFormElement() {
      return this.$refs.input.form;
    },
    setSearchTermsFromQuery() {
      const { entity_type: type, entity_id: value } = queryToObject(window.location.search);
      if (type && value) {
        this.searchTerms = [{ type, value: { data: value, operator: '=' } }];
      }
    },
    filteredSearchSubmit() {
      this.getFormElement().submit();
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
      @submit="filteredSearchSubmit"
    />

    <input ref="input" v-model="type" type="hidden" name="entity_type" />
    <input v-model="id" type="hidden" name="entity_id" />
  </div>
</template>
