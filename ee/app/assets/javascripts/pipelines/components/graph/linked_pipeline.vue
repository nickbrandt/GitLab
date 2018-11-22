<script>
import { GlTooltipDirective, GlButton } from '@gitlab/ui'
import CiStatus from '~/vue_shared/components/ci_icon.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CiStatus,
    GlButton,
  },
  props: {
    pipelineId: {
      type: Number,
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
      <gl-button
        v-gl-tooltip
        @click="$emit('pipelineClicked')"
        :title="tooltipText"
        class="linked-pipeline-content"
      >
        <ci-status :status="pipelineStatus" class="js-linked-pipeline-status" />

        <span class="linked-pipeline-project-name ci-status-text">{{ projectName }}</span>
        <span class="project-name-pipeline-id-separator ci-status-text">&#8226;</span>
        <span class="linked-pipeline-id ci-status-text">#{{ pipelineId }}</span>
      </gl-button>
    </div>
  </li>
</template>
