<script>
import { mapState, mapActions } from 'vuex';
import { GlBadge, GlButton, GlLoadingIcon } from '@gitlab/ui';

import Icon from '~/vue_shared/components/icon.vue';
import ProjectSelector from '~/vue_shared/components/project_selector/project_selector.vue';

import ProjectList from './project_list.vue';

export default {
  components: {
    GlBadge,
    GlButton,
    GlLoadingIcon,
    Icon,
    ProjectList,
    ProjectSelector,
  },
  computed: {
    ...mapState('projectSelector', [
      'projects',
      'isAddingProjects',
      'selectedProjects',
      'projectSearchResults',
      'searchCount',
      'messages',
    ]),
    isSearchingProjects() {
      return this.searchCount > 0;
    },
    hasProjectsSelected() {
      return this.selectedProjects.length > 0;
    },
  },
  methods: {
    ...mapActions('projectSelector', [
      'fetchSearchResults',
      'addProjects',
      'clearSearchResults',
      'toggleSelectedProject',
      'setSearchQuery',
      'removeProject',
    ]),
    addProjectsAndClearSearchResults() {
      this.addProjects();
      this.clearSearchResults();
    },
    searched(query) {
      this.setSearchQuery(query);
      this.fetchSearchResults();
    },
    projectClicked(project) {
      this.toggleSelectedProject(project);
    },
    projectRemoved(project) {
      this.removeProject(project.remove_path);
    },
  },
};
</script>

<template>
  <section class="container">
    <div class="row justify-content-center mt-md-4">
      <div class="col col-lg-7">
        <h2 class="h5 border-bottom mb-4 pb-3">
          {{ s__('SecurityDashboard|Add or remove projects from your dashboard') }}
        </h2>
        <div class="d-flex flex-column flex-md-row">
          <project-selector
            class="flex-grow mr-md-2"
            :project-search-results="projectSearchResults"
            :selected-projects="selectedProjects"
            :show-no-results-message="messages.noResults"
            :show-loading-indicator="isSearchingProjects"
            :show-minimum-search-query-message="messages.minimumQuery"
            :show-search-error-message="messages.searchError"
            @searched="searched"
            @projectClicked="projectClicked"
          />
          <div class="mb-3">
            <gl-button
              :disabled="!hasProjectsSelected"
              variant="success"
              @click="addProjectsAndClearSearchResults"
            >
              {{ s__('SecurityDashboard|Add projects') }}
            </gl-button>
          </div>
        </div>
      </div>
    </div>
    <div class="row justify-content-center mt-md-3">
      <project-list :projects="projects" class="col col-lg-7" @projectRemoved="projectRemoved" />
      <gl-loading-icon v-if="isAddingProjects" size="sm" />
    </div>
  </section>
</template>
