<script>
import { GlButton, GlDropdown, GlDropdownItem, GlFormInput } from '@gitlab/ui';

import { __ } from '~/locale';

import ProjectAvatar from '~/vue_shared/components/project_avatar/default.vue';

export default {
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlFormInput,
    ProjectAvatar,
  },

  props: {
    projects: {
      type: Array,
      required: true,
    },
  },

  data() {
    return {
      selectedProject: null,
      title: '',
    };
  },

  computed: {
    dropdownToggleText() {
      if (this.selectedProject) {
        return this.selectedProject.name_with_namespace;
      }

      return __('Select a project');
    },

    hasValidInput() {
      return this.title.trim() !== '' && this.selectedProject;
    },
  },

  methods: {
    cancel() {
      this.$emit('cancel');
    },

    createIssue() {
      if (!this.hasValidInput) {
        return;
      }

      const { selectedProject, title } = this;
      const { issues: issuesEndpoint } = selectedProject._links;
      this.$emit('submit', { issuesEndpoint, title });
    },
  },
};
</script>

<template>
  <div>
    <div class="row mb-3">
      <div class="col-sm">
        <label class="label-bold">{{ s__('Issue|Title') }}</label>
        <gl-form-input
          ref="titleInput"
          v-model="title"
          :placeholder="__('New issue title')"
          autofocus
        />
      </div>
      <div class="col-sm">
        <label class="label-bold">{{ __('Project') }}</label>
        <gl-dropdown
          :text="dropdownToggleText"
          class="w-100"
          menu-class="w-100"
          toggle-class="d-flex align-items-center justify-content-between text-truncate"
        >
          <gl-dropdown-item
            v-for="project in projects"
            :key="project.id"
            class="w-100"
            @click="selectedProject = project"
          >
            <project-avatar :project="project" :size="32" />
            {{ project.name }}
            <div class="text-secondary">{{ project.namespace.name }}</div>
          </gl-dropdown-item>
        </gl-dropdown>
      </div>
    </div>

    <div class="row my-1">
      <div class="col-sm flex-sm-grow-0 mb-2 mb-sm-0">
        <gl-button class="w-100" variant="success" :disabled="!hasValidInput" @click="createIssue">
          {{ __('Create issue') }}
        </gl-button>
      </div>
      <div class="col-sm flex-sm-grow-0 ml-auto">
        <gl-button class="w-100" @click="cancel">{{ __('Cancel') }}</gl-button>
      </div>
    </div>
  </div>
</template>
