<script>
import { GlFormGroup, GlButton, GlFormInput, GlForm, GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';
import createBranchMutation from '../graphql/mutations/create_branch.mutation.graphql';
import ProjectDropdown from './project_dropdown.vue';
import SourceBranchDropdown from './source_branch_dropdown.vue';

const DEFAULT_ALERT_VARIANT = 'danger';

export default {
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
  data() {
    return {
      selectedProject: null,
      selectedSourceBranchName: null,
      branchName: '',
      createBranchLoading: false,
      alertTitle: '',
      alertMessage: '',
      alertVariant: DEFAULT_ALERT_VARIANT,
      alertPrimaryButtonLink: '',
      alertPrimaryButtonText: '',
    };
  },
  computed: {
    selectedProjectId() {
      return this.selectedProject?.id;
    },
    showAlert() {
      return Boolean(this.alertMessage);
    },
  },
  methods: {
    displayAlert({
      title,
      message,
      variant = DEFAULT_ALERT_VARIANT,
      primaryButtonLink,
      primaryButtonText,
    } = {}) {
      this.alertTitle = title;
      this.alertMessage = message;
      this.alertVariant = variant;
      this.alertPrimaryButtonLink = primaryButtonLink;
      this.alertPrimaryButtonText = primaryButtonText;
    },
    onAlertDismiss() {
      this.alertTitle = '';
      this.alertMessage = '';
      this.alertVariant = DEFAULT_ALERT_VARIANT;
      this.alertPrimaryButtonLink = '';
      this.alertPrimaryButtonText = '';
    },
    async onProjectSelect(project) {
      this.selectedProject = project;
      this.selectedSourceBranchName = null; // reset branch selection
    },
    onSourceBranchSelect(branchName) {
      this.selectedSourceBranchName = branchName;
    },
    onError({ title, message } = {}) {
      this.displayAlert({
        message,
        title,
        variant: 'danger',
      });
    },
    onSubmit() {
      this.createBranch();
    },
    async createBranch() {
      this.createBranchLoading = true;
      this.$apollo
        .mutate({
          mutation: createBranchMutation,
          variables: {
            name: this.branchName,
            ref: this.selectedSourceBranchName,
            projectPath: this.selectedProject.fullPath,
          },
        })
        .then(({ data }) => {
          const { errors } = data.createBranch;
          if (errors.length > 0) {
            this.onError({
              title: __('Failed to create branch.'),
              message: errors[0],
            });
            return;
          }

          this.displayAlert({
            title: __('New branch was successfully created.'),
            message: __('You can now close this window and return to Jira'),
            variant: 'success',
            primaryButtonLink: 'jira',
            primaryButtonText: __('Return to Jira'),
          });
        })
        .catch(() => {
          this.onError({
            message: __('Failed to create branch. Please try again.'),
          });
        })
        .finally(() => {
          this.createBranchLoading = false;
        });
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
      class="gl-mb-5"
      :variant="alertVariant"
      :title="alertTitle"
      :primary-button-link="alertPrimaryButtonLink"
      :primary-button-text="alertPrimaryButtonText"
      @dismiss="onAlertDismiss"
    >
      {{ alertMessage }}
    </gl-alert>

    <gl-form @submit.prevent="onSubmit">
      <gl-form-group :label="$options.i18n.projectDropdownLabel" label-for="project-select">
        <input name="project_id" :value="selectedProjectId" type="hidden" />
        <project-dropdown
          :selected-project="selectedProject"
          @change="onProjectSelect"
          @error="onError"
        />
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
          @error="onError"
        />
      </gl-form-group>

      <div class="form-actions">
        <gl-button :loading="createBranchLoading" type="submit" variant="confirm">{{
          $options.i18n.formSubmitButtonText
        }}</gl-button>
      </div>
    </gl-form>
  </div>
</template>
