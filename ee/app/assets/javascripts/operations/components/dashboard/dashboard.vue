<script>
import { mapState, mapActions } from 'vuex';
import { GlLoadingIcon } from '@gitlab-org/gitlab-ui';
import DashboardProject from './project.vue';
import ProjectSearch from './project_search.vue';

export default {
  components: {
    DashboardProject,
    ProjectSearch,
    GlLoadingIcon,
  },
  props: {
    addPath: {
      type: String,
      required: true,
    },
    listPath: {
      type: String,
      required: true,
    },
    emptyDashboardSvgPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['projects', 'projectTokens', 'isLoadingProjects']),
    addIsDisabled() {
      return !this.projectTokens.length;
    },
  },
  created() {
    this.setProjectEndpoints({
      list: this.listPath,
      add: this.addPath,
    });
    this.fetchProjects();
  },
  methods: {
    ...mapActions(['addProjectsToDashboard', 'fetchProjects', 'setProjectEndpoints']),
    addProjects() {
      if (!this.addIsDisabled) {
        this.addProjectsToDashboard();
      }
    },
  },
};
</script>

<template>
  <div class="operations-dashboard">
    <nav class="breadcrumbs container-fluid container-limited">
      <div class="breadcrumbs-container">
        <h2 class="js-dashboard-title breadcrumbs-sub-title">
          {{ __('Operations Dashboard') }}
        </h2>
      </div>
    </nav>
    <div class="container-fluid container-limited prepend-top-default">
      <div class="d-flex align-items-center">
        <project-search class="flex-grow-1" />
        <button
          :class="{ disabled: addIsDisabled }"
          type="button"
          class="js-add-projects-button btn btn-success prepend-left-8"
          @click="addProjects"
        >
          {{ __('Add projects') }}
        </button>
      </div>
      <div
        v-if="projects.length"
        class="row m-0 prepend-top-default"
      >
        <div
          v-for="project in projects"
          :key="project.id"
          class="col-12 col-md-6 odds-md-pad-right evens-md-pad-left"
        >
          <dashboard-project :project="project" />
        </div>
      </div>
      <div
        v-else-if="!isLoadingProjects"
        class="row prepend-top-20 text-center"
      >
        <div class="col-12 d-flex justify-content-center svg-content">
          <img
            :src="emptyDashboardSvgPath"
            class="js-empty-state-svg col-12 prepend-top-20"
          />
        </div>
        <h4 class="js-title col-12 prepend-top-20">
          {{ s__('OperationsDashboard|Add a project to the dashboard') }}
        </h4>
        <div class="col-12 d-flex justify-content-center">
          <span class="js-sub-title mw-460 text-tertiary">
            {{ s__(`OperationsDashboard|The operations dashboard provides a summary of each project's
              operational health, including pipeline and alert status.`) }}
          </span>
        </div>
      </div>
      <gl-loading-icon
        v-else
        :size="2"
        class="prepend-top-20"
      />
    </div>
  </div>
</template>
