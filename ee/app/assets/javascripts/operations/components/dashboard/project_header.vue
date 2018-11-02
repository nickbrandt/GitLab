<script>
import Icon from '~/vue_shared/components/icon.vue';
import ProjectAvatar from '~/vue_shared/components/project_avatar/default.vue';

export default {
  components: {
    Icon,
    ProjectAvatar,
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
    <div class="dropdown">
      <div
        class="d-flex align-items-center ml-2"
        data-toggle="dropdown"
      >
        <icon
          name="ellipsis_v"
          class="text-secondary"
        />
      </div>
      <div class="dropdown-menu dropdown-menu-right">
        <button
          type="button"
          class="js-remove-button dropdown-item btn-link text-danger prepend-left-default append-right-default outline-0"
          @click="onRemove"
        >
          {{ __('Remove') }}
        </button>
      </div>
    </div>
  </div>
</template>
