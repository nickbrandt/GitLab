<script>
import ProjectAvatarDefault from '~/vue_shared/components/project_avatar/default.vue';

export default {
  components: {
    ProjectAvatarDefault,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
    expanded: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
};
</script>

<template>
  <div class="context-header ide-context-header">
    <a :href="project.web_url" :title="s__('IDE|Go to project')">
      <project-avatar-default :project="project" :size="40" />
      <span v-if="expanded" class="ide-sidebar-project-title">
        <span class="sidebar-context-title"> {{ project.name }} </span>
        <span class="sidebar-context-title text-secondary">
          {{ project.path_with_namespace }}
        </span>
      </span>
    </a>
  </div>
</template>
