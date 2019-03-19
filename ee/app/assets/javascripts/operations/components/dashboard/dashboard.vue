<script>
import { mapState, mapActions } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
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
    emptyDashboardHelpPath: {
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
    <div
      class="page-title-holder flex-fill d-flex flex-column flex-md-row align-items-md-end align-items-stretch"
    >
      <div class="flex-fill append-right-20">
        <h1 class="js-dashboard-title page-title text-nowrap">{{ __('Operations Dashboard') }}</h1>
      </div>
      <div class="d-flex flex-fill align-items-end append-bottom-default">
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
    </div>
    <div class="prepend-top-default">
      <div v-if="projects.length" class="row m-0 prepend-top-default">
        <div
          v-for="project in projects"
          :key="project.id"
          class="col-12 col-md-6 odds-md-pad-right evens-md-pad-left"
        >
          <dashboard-project :project="project" />
        </div>
      </div>
      <div v-else-if="!isLoadingProjects" class="row prepend-top-20 text-center">
        <div class="col-12 d-flex justify-content-center svg-content">
          <img :src="emptyDashboardSvgPath" class="js-empty-state-svg col-12 prepend-top-20" />
        </div>
        <h4 class="js-title col-12 prepend-top-20">
          {{ s__('OperationsDashboard|Add a project to the dashboard') }}
        </h4>
        <div class="col-12 d-flex justify-content-center">
          <span class="js-sub-title mw-460 text-tertiary text-left">
            {{
              s__(`OperationsDashboard|The operations dashboard provides a summary of each project's
              operational health, including pipeline and alert statuses.`)
            }}
          </span>
        </div>
        <div class="col-12">
          <a
            :href="emptyDashboardHelpPath"
            class="js-documentation-link btn btn-primary prepend-top-default append-bottom-default"
          >
            {{ __('View documentation') }}
          </a>
        </div>
      </div>
      <gl-loading-icon v-else :size="2" class="prepend-top-20" />
    </div>
  </div>
</template>
