<script>
import { GlBadge, GlButton, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import ProjectAvatar from '~/vue_shared/components/project_avatar/default.vue';

export default {
  components: {
    GlBadge,
    GlButton,
    GlLoadingIcon,
    Icon,
    ProjectAvatar,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    projects: {
      type: Array,
      required: true,
    },
  },
  methods: {
    projectRemoved(project) {
      this.$emit('projectRemoved', project);
    },
  },
};
</script>

<template>
  <section>
    <div>
      <h3 class="h5 text-secondary border-bottom mb-3 pb-2">
        {{ s__('SecurityDashboard|Projects added') }}
        <gl-badge>{{ projects.length }}</gl-badge>
      </h3>
      <ul v-if="projects.length" class="list-unstyled">
        <li
          v-for="project in projects"
          :key="project.id"
          class="d-flex align-items-center py-1 js-projects-list-project-item"
        >
          <project-avatar class="flex-shrink-0" :project="project" :size="32" />
          <span>
            {{ project.name_with_namespace }}
          </span>
          <gl-button
            v-gl-tooltip
            class="ml-auto bg-transparent border-0 p-0 text-secondary js-projects-list-project-remove"
            :title="s__('SecurityDashboard|Remove project from dashboard')"
            @click="projectRemoved(project)"
          >
            <icon name="remove" />
          </gl-button>
        </li>
      </ul>
      <p v-else class="text-secondary js-projects-list-empty-message">
        {{
          s__('SecurityDashboard|Select a project to add by using the project search field above.')
        }}
      </p>
    </div>
  </section>
</template>
