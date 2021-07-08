<script>
import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import getProjectsQuery from '../../graphql/queries/get_projects.query.graphql';

export default {
  PROJECTS_PER_PAGE: 20,
  projectQueryPageInfo: {
    endCursor: '',
  },
  components: {
    GlDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
    GlLoadingIcon,
  },
  data() {
    return {
      initialProjectsLoading: true,
      projectSearchQuery: '',
    };
  },
  apollo: {
    projects: {
      query: getProjectsQuery,
      variables() {
        return {
          search: this.projectSearchQuery,
          first: this.$options.PROJECTS_PER_PAGE,
          after: this.$options.projectQueryPageInfo.endCursor,
          searchNamespaces: true,
          sort: 'similarity',
        };
      },
      update(data) {
        return data?.projects?.nodes ?? [];
      },
      result({ data }) {
        this.initialProjectsLoading = false;
        this.$options.projectQueryPageInfo.endCursor = data?.projects.pageInfo.endCursor;
      },
    },
  },
  computed: {
    isLoadingProjects() {
      return Boolean(this.$apollo.queries.projects.loading);
    },
    projectDropdownText() {
      return this.selectedProject?.nameWithNamespace || __('Select a project');
    },
  },
  methods: {
    async onProjectSelect(project) {
      this.$emit('change', project);
    },
    onError(err) {
      this.$emit('error', err);
    },
  },
};
</script>

<template>
  <gl-dropdown :text="projectDropdownText" :loading="initialProjectsLoading">
    <template #header>
      <gl-search-box-by-type v-model.trim="projectSearchQuery" :debounce="250" />
    </template>

    <gl-loading-icon v-show="isLoadingProjects" />
    <gl-dropdown-item
      v-for="project in projects"
      v-show="!isLoadingProjects"
      :key="project.id"
      @click="onProjectSelect(project)"
    >
      {{ project.nameWithNamespace }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
