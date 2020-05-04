<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import { GlDeprecatedButton } from '@gitlab/ui';
import ProjectSelector from '~/vue_shared/components/project_selector/project_selector.vue';
import ProjectList from './project_list.vue';

export default {
  components: {
    GlDeprecatedButton,
    ProjectList,
    ProjectSelector,
  },
  computed: {
    ...mapState('projectSelector', [
      'pageInfo',
      'projects',
      'selectedProjects',
      'projectSearchResults',
      'messages',
    ]),
    ...mapGetters('projectSelector', [
      'canAddProjects',
      'isSearchingProjects',
      'isUpdatingProjects',
    ]),
  },
  methods: {
    ...mapActions('projectSelector', [
      'fetchSearchResults',
      'fetchSearchResultsNextPage',
      'addProjects',
      'clearSearchResults',
      'toggleSelectedProject',
      'setSearchQuery',
      'removeProject',
    ]),
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
        <h3 class="text-3 font-weight-bold border-bottom mb-4 pb-3">
          {{ s__('SecurityReports|Add or remove projects from your dashboard') }}
        </h3>
        <div class="d-flex flex-column flex-md-row">
          <project-selector
            class="flex-grow mr-md-2"
            :project-search-results="projectSearchResults"
            :selected-projects="selectedProjects"
            :show-no-results-message="messages.noResults"
            :show-loading-indicator="isSearchingProjects"
            :show-minimum-search-query-message="messages.minimumQuery"
            :show-search-error-message="messages.searchError"
            :total-results="pageInfo.total"
            @searched="searched"
            @projectClicked="projectClicked"
            @bottomReached="fetchSearchResultsNextPage"
          />
          <div class="mb-3">
            <gl-deprecated-button
              :disabled="!canAddProjects"
              variant="success"
              @click="addProjects"
            >
              {{ s__('SecurityReports|Add projects') }}
            </gl-deprecated-button>
          </div>
        </div>
      </div>
    </div>
    <div class="row justify-content-center mt-md-3">
      <project-list
        :projects="projects"
        :show-loading-indicator="isUpdatingProjects"
        class="col col-lg-7"
        @projectRemoved="projectRemoved"
      />
    </div>
  </section>
</template>
