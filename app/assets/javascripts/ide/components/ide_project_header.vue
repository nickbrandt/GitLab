<script>
export default {
  props: {
    project: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div class="context-header ide-context-header">
    <a :href="project.web_url" :title="s__('IDE|Go to project')" class="ide-header-body">
      <span class="ide-sidebar-project-title">
        <span class="sidebar-context-title"> {{ project.name }} </span>
        <span class="sidebar-context-title text-secondary">
          {{ project.path_with_namespace }}
        </span>
      </span>
    </a>
  </div>
</template>
