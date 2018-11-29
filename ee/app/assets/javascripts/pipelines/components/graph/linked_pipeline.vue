<script>
import { GlLoadingIcon, GlTooltipDirective, GlLink } from '@gitlab/ui';
import CiStatus from '~/vue_shared/components/ci_icon.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CiStatus,
    GlLoadingIcon,
    GlLink,
  },
  props: {
    pipelineId: {
      type: Number,
      required: true,
    },
    pipelinePath: {
      type: String,
      required: true,
    },
    pipelineStatus: {
      type: Object,
      required: true,
    },
    projectName: {
      type: String,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    tooltipText() {
      return `${this.projectName} - ${this.pipelineStatus.label}`;
    },
  },
};
</script>

<template>
  <li class="linked-pipeline build">
    <div class="curve"></div>
    <div>
      <gl-link
        v-gl-tooltip
        :href="pipelinePath"
        :title="tooltipText"
        class="js-linked-pipeline-content linked-pipeline-content"
      >
        <span class="js-linked-pipeline-status ci-status-text">
          <gl-loading-icon v-if="isLoading" class="js-linked-pipeline-loading" />
          <ci-status v-else :status="pipelineStatus" class="js-linked-pipeline-status" />
        </span>
        <span class="linked-pipeline-project-name">{{ projectName }}</span>
        <span class="project-name-pipeline-id-separator">&#8226;</span>
        <span class="js-linked-pipeline-id">#{{ pipelineId }}</span>
      </gl-link>
    </div>
  </li>
</template>
