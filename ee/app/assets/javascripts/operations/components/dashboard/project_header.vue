<script>
import Icon from '~/vue_shared/components/icon.vue';
import ProjectAvatar from '~/vue_shared/components/project_avatar/default.vue';
import { GlButton, GlLink, GlTooltipDirective } from '@gitlab/ui';

export default {
  components: {
    Icon,
    ProjectAvatar,
    GlButton,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
    hasPipelineFailed: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasErrors: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    headerClasses() {
      return {
        'dashboard-card-header-warning': this.hasErrors,
        'dashboard-card-header-failed': this.hasPipelineFailed,
        'bg-light': !this.hasErrors && !this.hasPipelineFailed,
      };
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
  <div :class="headerClasses" class="card-header border-0 py-2 d-flex align-items-center">
    <project-avatar :project="project" :size="24" class="flex-shrink-0 border rounded" />
    <div class="flex-grow-1 block-truncated">
      <gl-link
        v-gl-tooltip
        class="js-project-link cgray"
        :href="project.web_url"
        :title="project.name_with_namespace"
      >
        <span class="js-project-namespace">{{ project.namespace.name }} /</span>
        <span class="js-project-name bold"> {{ project.name }}</span>
      </gl-link>
    </div>
    <div class="dropdown js-more-actions">
      <gl-button
        v-gl-tooltip
        class="js-more-actions-toggle d-flex align-items-center bg-transparent border-0 p-0 ml-2"
        data-toggle="dropdown"
        :title="__('More actions')"
      >
        <icon name="ellipsis_v" class="text-secondary" />
      </gl-button>
      <ul class="dropdown-menu dropdown-menu-right">
        <li>
          <gl-button class="btn btn-transparent js-remove-button" @click="onRemove">
            <span class="text-danger"> {{ __('Remove') }} </span>
          </gl-button>
        </li>
      </ul>
    </div>
  </div>
</template>
