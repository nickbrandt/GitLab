<script>
import { GlLink, GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import ReviewAppLink from '~/vue_merge_request_widget/components/review_app_link.vue';

export default {
  components: {
    Icon,
    ReviewAppLink,
    GlBadge,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    environment: {
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
  tooltips: {
    information: s__('EnviornmentDashboard|You are looking at the last updated environment'),
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
};
</script>

<template>
  <div :class="headerClasses" class="card-header border-0 py-2 d-flex align-items-center">
    <div class="flex-grow-1 block-truncated">
      <gl-link
        v-gl-tooltip
        class="js-environment-link cgray"
        :href="environment.environment_path"
        :title="environment.name"
      >
        <span class="js-environment-name bold"> {{ environment.name }}</span>
      </gl-link>
      <gl-badge v-if="environment.within_folder" :pill="true" class="dashboard-card-icon">{{
        environment.size
      }}</gl-badge>
    </div>
    <icon
      v-if="environment.within_folder"
      v-gl-tooltip
      :title="$options.tooltips.information"
      name="information"
      class="dashboard-card-icon"
    />
    <review-app-link
      v-else-if="environment.external_url"
      :link="environment.external_url"
      :is-current="true"
      css-class="btn btn-default btn-sm"
    />
  </div>
</template>
