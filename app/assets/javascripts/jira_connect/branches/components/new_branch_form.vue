<script>
import { GlFormGroup, GlButton, GlFormInput, GlForm, GlAlert } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { __ } from '~/locale';
import ProjectDropdown from './project_dropdown.vue';
import SourceBranchDropdown from './source_branch_dropdown.vue';

export default {
  CSRF_TOKEN: csrf.token,
  name: 'JiraConnectNewBranch',
  components: {
    GlFormGroup,
    GlButton,
    GlFormInput,
    GlForm,
    GlAlert,
    ProjectDropdown,
    SourceBranchDropdown,
  },
  inject: ['formEndpoint'],
  data() {
    return {
      selectedProject: null,
      selectedSourceBranchName: null,
      branchName: '',
      alertTitle: '',
      alertMessage: '',
    };
  },
  computed: {
    selectedProjectId() {
      return this.selectedProject?.id;
    },
    showAlert() {
      return Boolean(this.alertTitle && this.alertMessage);
    },
  },
  methods: {
    async onProjectSelect(project) {
      this.selectedProject = project;
      this.selectedSourceBranchName = null; // reset branch selection
    },
    onSourceBranchSelect(branchName) {
      this.selectedSourceBranchName = branchName;
    },
    onError({ title, message } = {}) {
      this.alertTitle = title;
      this.alertMessage = message;
    },
    onAlertDismiss() {
      this.alertTitle = null;
      this.alertMessage = null;
    },
  },
  i18n: {
    projectDropdownLabel: __('Project'),
    branchNameInputLabel: __('Branch name'),
    sourceBranchDropdownLabel: __('Source branch'),
    formSubmitButtonText: __('Create branch'),
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

      <gl-form-group :label="$options.i18n.projectDropdownLabel" label-for="project-select">
        <input name="project_id" :value="selectedProjectId" type="hidden" />
        <project-dropdown :selected-project="selectedProject" @change="onProjectSelect" />
      </gl-form-group>

      <gl-form-group :label="$options.i18n.sourceBranchDropdownLabel">
        <gl-form-input v-model="branchName" type="text" name="branch_name" required />
      </gl-form-group>

      <gl-form-group :label="$options.i18n.branchNameInputLabel">
        <input name="source_branch" :value="selectedSourceBranchName" type="hidden" />
        <source-branch-dropdown
          :selected-project="selectedProject"
          :selected-branch-name="selectedSourceBranchName"
          @change="onSourceBranchSelect"
        />
      </gl-form-group>

      <div class="form-actions">
        <gl-button type="submit" variant="confirm">{{
          $options.i18n.formSubmitButtonText
        }}</gl-button>
      </div>
    </gl-form>
  </div>
</template>
