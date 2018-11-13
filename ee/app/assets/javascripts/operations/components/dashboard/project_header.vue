<script>
import Icon from '~/vue_shared/components/icon.vue';
import ProjectAvatar from '~/vue_shared/components/project_avatar/default.vue';
import { GlTooltipDirective } from '@gitlab-org/gitlab-ui';

export default {
  components: {
    Icon,
    ProjectAvatar,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
  },
  methods: {
    onRemove() {
      this.$emit('remove', this.project.remove_path);
    },
  },
};
</script>

<template>
  <div class="project-header d-flex align-items-center">
    <project-avatar
      :project="project"
      :size="20"
      class="flex-shrink-0"
    />
    <div class="flex-grow-1">
      <a
        class="js-project-link cgray"
        :href="project.web_url"
      >
        <span class="js-name-with-namespace bold">
          {{ project.name_with_namespace }}
        </span>
      </a>
    </div>
    <div class="dropdown js-more-actions">
      <div
        v-gl-tooltip
        class="js-more-actions-toggle d-flex align-items-center ml-2"
        data-toggle="dropdown"
        :title="__('More actions')"
      >
        <icon
          name="ellipsis_v"
          class="text-secondary"
        />
      </div>
      <ul class="dropdown-menu dropdown-menu-right">
        <li>
          <button
            class="btn btn-transparent js-remove-button"
            type="button"
            @click="onRemove">
            <span class="text-danger">
              {{ __('Remove') }}
            </span>
          </button>
        </li>
      </ul>
    </div>
  </div>
</template>
