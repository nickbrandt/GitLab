<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlFormGroup,
  GlButton,
  GlFormInput,
  GlSearchBoxByType,
  GlLoadingIcon,
  GlForm,
  GlAlert,
} from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';

import { __ } from '~/locale';
import getProjectQuery from '../graphql/queries/get_project.query.graphql';
import getProjectsQuery from '../graphql/queries/get_projects.query.graphql';

export default {
  MINIMUM_QUERY_LENGTH: 3,
  PROJECTS_PER_PAGE: 20,
  BRANCHES_PER_PAGE: 20,
  CSRF_TOKEN: csrf.token,
  name: 'JiraConnectNewBranch',
  projectQueryPageInfo: {
    endCursor: '',
  },
  components: {
    GlDropdown,
    GlDropdownItem,
    GlFormGroup,
    GlButton,
    GlFormInput,
    GlSearchBoxByType,
    GlLoadingIcon,
    GlForm,
    GlAlert,
  },
  inject: ['formEndpoint'],
  data() {
    return {
      projectSearchQuery: '',
      sourceBranchSearchQuery: '',
      initialProjectsLoading: true,
      initialSourceBranchNamesLoading: false,
      sourceBranchNamesLoading: false,
      sourceBranchNames: [],
      selectedProject: null,
      selectedSourceBranchName: null,
      branchName: '',
      alertTitle: '',
      alertMessage: '',
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
    hasSelectedProject() {
      return Boolean(this.selectedProject);
    },
    hasSelectedSourceBranch() {
      return Boolean(this.selectedSourceBranchName);
    },
    projectDropdownText() {
      return this.selectedProject?.nameWithNamespace || __('Select a project');
    },
    branchDropdownText() {
      return this.selectedSourceBranchName || __('Select a branch');
    },
    showAlert() {
      return Boolean(this.alertTitle && this.alertMessage);
    },
  },
  methods: {
    async onProjectSelect(project) {
      this.selectedProject = project;
      this.selectedSourceBranchName = null; // reset branch selection

      this.initialSourceBranchNamesLoading = true;
      await this.fetchSourceBranchNames({ projectPath: this.selectedProject.fullPath });
      this.initialSourceBranchNamesLoading = false;
    },
    onSourceBranchSelect(branchName) {
      this.selectedSourceBranchName = branchName;
    },
    onSourceBranchSearchQuery(branchSearchQuery) {
      this.branchSearchQuery = branchSearchQuery;
      this.fetchSourceBranchNames({
        projectPath: this.selectedProject.fullPath,
        searchPattern: this.branchSearchQuery,
      });
    },
    onError({ title, message } = {}) {
      this.alertTitle = title;
      this.alertMessage = message;
    },
    onAlertDismiss() {
      this.alertTitle = null;
      this.alertMessage = null;
    },
    async fetchSourceBranchNames({ projectPath, searchPattern = '*' } = {}) {
      this.sourceBranchNamesLoading = true;
      try {
        const { data } = await this.$apollo.query({
          query: getProjectQuery,
          variables: {
            projectPath,
            branchNamesLimit: this.$options.BRANCHES_PER_PAGE,
            branchNamesOffset: 0,
            branchNamesSearchPattern: `*${searchPattern}*`,
          },
        });

        const { branchNames, rootRef } = data?.project.repository || {};
        this.sourceBranchNames = branchNames || [];
        // use root ref as the default selection
        if (!this.hasSelectedSourceBranch) {
          this.selectedSourceBranchName = rootRef;
        }
      } catch (err) {
        this.onError({
          title: 'Something went wrong while fetching source branches.',
          message: err.message,
        });
      } finally {
        this.sourceBranchNamesLoading = false;
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="showAlert"
      :title="$options.i18n.integrationCreated.title"
      @dismiss="onAlertDismiss"
    >
      {{ alertParams.message }}
    </gl-alert>

    <gl-form method="post" :action="formEndpoint">
      <input :value="$options.CSRF_TOKEN" type="hidden" name="authenticity_token" />

      <gl-form-group
        :invalid-feedback="__('Please select a project')"
        :label="__('Project')"
        label-for="project-select"
      >
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
      </gl-form-group>

      <gl-form-group :label="__('Branch name')">
        <gl-form-input v-model="branchName" type="text" name="branch_name" required />
      </gl-form-group>

      <gl-form-group :label="__('Source branch')">
        <input name="source_branch" :value="selectedSourceBranchName" type="hidden" />
        <gl-dropdown
          :text="branchDropdownText"
          :loading="initialSourceBranchNamesLoading"
          :disabled="!hasSelectedProject"
          :class="{ 'gl-font-monospace': hasSelectedSourceBranch }"
        >
          <template #header>
            <gl-search-box-by-type
              :debounce="250"
              :value="sourceBranchSearchQuery"
              @input="onSourceBranchSearchQuery"
            />
          </template>

          <gl-loading-icon v-show="sourceBranchNamesLoading" />
          <gl-dropdown-item
            v-for="branchName in sourceBranchNames"
            v-show="!sourceBranchNamesLoading"
            :key="branchName"
            :is-checked="branchName === selectedSourceBranchName"
            is-check-item
            class="gl-font-monospace"
            @click="onSourceBranchSelect(branchName)"
          >
            {{ branchName }}
          </gl-dropdown-item>
        </gl-dropdown>
      </gl-form-group>

      <div class="form-actions">
        <gl-button type="submit" variant="confirm">{{ __('Create branch') }}</gl-button>
      </div>
    </gl-form>
  </div>
</template>
