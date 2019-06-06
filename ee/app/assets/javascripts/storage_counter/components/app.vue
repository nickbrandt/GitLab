<script>
import Project from './project.vue';
import query from '../queries/storage.graphql';

export default {
  components: {
    Project,
  },
  props: {
    namespacePath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    namespace: {
      query,
      variables() {
        return {
          fullPath: this.namespacePath,
        };
      },
      update: data => ({
        projects: data.namespace.projects.edges.map(({ node }) => node),
      }),
    },
  },
  data() {
    return {
      namespace: {},
    };
  },
};
</script>
<template>
  <div class="ci-table" role="grid">
    <div
      class="gl-responsive-table-row table-row-header bg-gray-light pl-2 border-top mt-3 lh-100"
      role="row"
    >
      <div class="table-section section-70 font-weight-bold" role="columnheader">
        {{ __('Project') }}
      </div>
      <div class="table-section section-30 font-weight-bold" role="columnheader">
        {{ __('Usage') }}
      </div>
    </div>

    <project v-for="project in namespace.projects" :key="project.id" :project="project" />
  </div>
</template>
