<script>
import { GlFilteredSearch } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { queryToObject } from '~/lib/utils/url_utility';
import UserToken from './tokens/user_token.vue';
import ProjectToken from './tokens/project_token.vue';
import GroupToken from './tokens/group_token.vue';

const DEFAULT_TOKEN_OPTIONS = {
  operators: [{ value: '=', description: __('is'), default: 'true' }],
  unique: true,
};
const FILTER_TOKENS = [
  {
    ...DEFAULT_TOKEN_OPTIONS,
    icon: 'user',
    title: s__('AuditLogs|User Events'),
    type: 'User',
    token: UserToken,
  },
  {
    ...DEFAULT_TOKEN_OPTIONS,
    icon: 'bookmark',
    title: s__('AuditLogs|Project Events'),
    type: 'Project',
    token: ProjectToken,
  },
  {
    ...DEFAULT_TOKEN_OPTIONS,
    icon: 'group',
    title: s__('AuditLogs|Group Events'),
    type: 'Group',
    token: GroupToken,
  },
];
const ALLOWED_FILTER_TYPES = FILTER_TOKENS.map(token => token.type);

export default {
  components: {
    GlFilteredSearch,
  },
  data() {
    return {
      searchTerms: [],
    };
  },
  computed: {
    searchTerm() {
      return this.searchTerms.find(term => ALLOWED_FILTER_TYPES.includes(term.type));
    },
    filterTokens() {
      // This limits the user to search by only one of the available tokens
      const { searchTerm } = this;
      if (searchTerm?.type) {
        return FILTER_TOKENS.map(token => ({
          ...token,
          disabled: searchTerm.type !== token.type,
        }));
      }
      return FILTER_TOKENS;
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
  <div class="input-group bg-white flex-grow-1" data-qa-selector="admin_audit_log_filter">
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
