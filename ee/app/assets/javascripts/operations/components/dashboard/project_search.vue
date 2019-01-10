<script>
import { mapState, mapActions } from 'vuex';
import _ from 'underscore';
import { __, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import ProjectAvatar from '~/vue_shared/components/project_avatar/default.vue';
import { GlLoadingIcon } from '@gitlab/ui';
import TokenizedInput from '../tokenized_input/input.vue';
import inputFocus from '../../mixins';

const inputSearchDelay = 300;

export default {
  components: {
    Icon,
    ProjectAvatar,
    TokenizedInput,
    GlLoadingIcon,
  },
  mixins: [inputFocus],
  data() {
    return {
      hasSearchedInput: false,
    };
  },
  computed: {
    ...mapState(['inputValue', 'projectTokens', 'projectSearchResults', 'searchCount']),
    isSearchingProjects() {
      return this.searchCount > 0;
    },
    searchDescription() {
      return sprintf(__('"%{query}" in projects'), { query: this.inputValue });
    },
    shouldShowSearch() {
      return this.inputValue.length && this.isInputFocused;
    },
    foundNoResults() {
      return !this.projectSearchResults.length && this.hasSearchedInput;
    },
  },
  watch: {
    inputValue() {
      this.queryInputInProjects();
    },
  },
  methods: {
    ...mapActions(['addProjectToken', 'searchProjects', 'clearProjectSearchResults']),
    queryInputInProjects: _.debounce(function search() {
      this.searchProjects(this.inputValue);
      this.hasSearchedInput = true;
    }, inputSearchDelay),
  },
};
</script>

<template>
  <div :class="{ show: shouldShowSearch }" class="dropdown">
    <tokenized-input @focus="onFocus" @blur="onBlur" />
    <div class="js-search-results dropdown-menu w-100 mw-100" @mousedown.prevent>
      <div class="py-2 px-4 text-tertiary"><icon name="search" /> {{ searchDescription }}</div>
      <div class="dropdown-divider"></div>
      <gl-loading-icon v-if="isSearchingProjects" :size="2" class="py-2 px-4" />
      <div v-else-if="foundNoResults" class="py-2 px-4 text-tertiary">
        {{ __('Sorry, no projects matched your search') }}
      </div>
      <button
        v-for="project in projectSearchResults"
        :key="project.id"
        type="button"
        class="js-search-result dropdown-item btn-link d-flex align-items-center cgray py-2 px-4"
        @mousedown="addProjectToken(project)"
      >
        <project-avatar :project="project" :size="20" class="flex-shrink-0 mr-3" />
        <div class="flex-grow-1">
          <div class="js-name-with-namespace bold ws-initial">
            {{ project.name_with_namespace }}
          </div>
        </div>
      </button>
    </div>
  </div>
</template>
