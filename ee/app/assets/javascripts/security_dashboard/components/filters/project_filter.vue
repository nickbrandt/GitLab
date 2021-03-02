<script>
import {
  GlDropdownDivider,
  GlLoadingIcon,
  GlDropdownText,
  GlSafeHtmlDirective as SafeHtml,
} from '@gitlab/ui';
import { escapeRegExp } from 'lodash';
import createFlash from '~/flash';
import { s__, __ } from '~/locale';
import { PROJECT_ID_PREFIX } from '../../constants';
import groupProjects from '../../graphql/queries/group_projects.query.graphql';
import { PROJECT_LOADING_ERROR_MESSAGE, mapProjects } from '../../helpers';
import FilterBody from './filter_body.vue';
import FilterItem from './filter_item.vue';
import StandardFilter from './standard_filter.vue';

const SEARCH_TERM_MINIMUM_LENGTH = 3;
const SELECTED_PROJECTS_MAX_COUNT = 100;

export default {
  components: {
    FilterBody,
    FilterItem,
    GlDropdownDivider,
    GlLoadingIcon,
    GlDropdownText,
  },
  directives: { SafeHtml },
  extends: StandardFilter,
  inject: ['groupFullPath'],
  data: () => ({
    projectsCache: {},
    projects: [],
    hasDropdownBeenOpened: false,
  }),
  computed: {
    options() {
      return Object.values(this.projectsCache);
    },
    selectedSet() {
      return new Set(this.selectedOptions.map((x) => x.id));
    },
    selectableProjects() {
      return this.isSearching ? this.projects : this.projects.filter((x) => !this.isSelected(x.id));
    },
    isLoadingProjects() {
      return this.$apollo.queries.projects.loading;
    },
    isLoadingProjectsById() {
      return this.$apollo.queries.projectsById.loading;
    },
    isSearchTooShort() {
      return this.isSearching && this.searchTerm.length < SEARCH_TERM_MINIMUM_LENGTH;
    },
    isSearching() {
      return this.searchTerm.length > 0;
    },
    showSelectedProjectsSection() {
      return this.selectedOptions.length && !this.isSearching;
    },
    showAllOption() {
      return !this.isLoadingProjects && !this.isSearching && !this.isMaxProjectsSelected;
    },
    isMaxProjectsSelected() {
      return this.selectedOptions.length >= SELECTED_PROJECTS_MAX_COUNT;
    },
    uncachedIds() {
      const ids = this.querystringIds.includes(this.filter.allOption.id) ? [] : this.querystringIds;
      return ids.filter((id) => !this.projectsCache[id]);
    },
  },
  apollo: {
    // Gets the projects from the project IDs in the querystring and adds them to the cache.
    projectsById: {
      query: groupProjects,
      manual: true,
      variables() {
        return {
          pageSize: 20,
          fullPath: this.groupFullPath,
          // The IDs have to be in the format "gid://gitlab/Project/${projectId}"
          ids: this.uncachedIds.map((id) => `${PROJECT_ID_PREFIX}${id}`),
        };
      },
      result({ data }) {
        const projects = mapProjects(data.group.projects.nodes);
        projects.forEach((project) => {
          this.$set(this.projectsCache, project.id, project);
        });
      },
      error() {
        createFlash({ message: PROJECT_LOADING_ERROR_MESSAGE });
      },
      skip() {
        return !this.uncachedIds.length;
      },
    },
    // Gets the projects for the group with an optional search, to show as dropdown options.
    projects: {
      query: groupProjects,
      variables() {
        return {
          fullPath: this.groupFullPath,
          search: this.searchTerm,
        };
      },
      update(data) {
        return mapProjects(data.group.projects.nodes);
      },
      result() {
        this.projects.forEach((project) => {
          this.$set(this.projectsCache, project.id, project);
        });
      },
      error() {
        createFlash({ message: PROJECT_LOADING_ERROR_MESSAGE });
      },
      skip() {
        return !this.hasDropdownBeenOpened || this.isSearchTooShort || this.isMaxProjectsSelected;
      },
    },
  },
  methods: {
    setDropdownOpened() {
      this.hasDropdownBeenOpened = true;
    },
    highlightSearchTerm(name) {
      // If we use the regex with no search term, it will wrap every character with <b>, i.e.
      // '<b>1</b><b>2</b><b>3</b>'.
      if (!this.isSearching) {
        return name;
      }
      // If the search term is "sec rep", split it into "sec|rep" so that a project with the name
      // "Security Reports" is highlighted as "SECurity REPorts".
      const terms = escapeRegExp(this.searchTerm).split(' ').join('|');
      const regex = new RegExp(`(${terms})`, 'gi');
      return name.replace(regex, '<b>$1</b>');
    },
  },
  i18n: {
    enterMoreCharactersToSearch: __('Enter at least three characters to search'),
    maxProjectsSelected: s__('SecurityReports|Maximum selected projects limit reached'),
    noMatchingResults: __('No matching results'),
  },
};
</script>

<template>
  <filter-body
    v-model.trim="searchTerm"
    :name="filter.name"
    :selected-options="selectedOptionsOrAll"
    :show-search-box="true"
    :loading="isLoadingProjectsById"
    @dropdown-show="setDropdownOpened"
  >
    <div v-if="showSelectedProjectsSection" data-testid="selected-projects-section">
      <filter-item
        v-for="project in selectedOptions"
        :key="project.id"
        :is-checked="true"
        :text="project.name"
        @click="toggleOption(project)"
      />

      <gl-dropdown-divider />
    </div>

    <filter-item
      v-if="showAllOption"
      :is-checked="isNoOptionsSelected"
      :text="filter.allOption.name"
      data-testid="allOption"
      @click="deselectAllOptions"
    />

    <gl-loading-icon v-if="isLoadingProjects" size="md" class="gl-mt-4 gl-mb-3" />
    <gl-dropdown-text v-else-if="isMaxProjectsSelected">
      {{ $options.i18n.maxProjectsSelected }}
    </gl-dropdown-text>
    <gl-dropdown-text v-else-if="isSearchTooShort">
      {{ $options.i18n.enterMoreCharactersToSearch }}
    </gl-dropdown-text>
    <gl-dropdown-text v-else-if="!projects.length">
      {{ $options.i18n.noMatchingResults }}
    </gl-dropdown-text>
    <template v-else>
      <filter-item
        v-for="project in selectableProjects"
        :key="project.id"
        :is-checked="isSelected(project.id)"
        @click="toggleOption(project)"
      >
        <div v-safe-html="highlightSearchTerm(project.name)" class="gl-text-truncate"></div>
      </filter-item>
    </template>
  </filter-body>
</template>
