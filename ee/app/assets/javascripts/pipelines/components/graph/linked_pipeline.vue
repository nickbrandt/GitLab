<script>
import { GlTooltipDirective, GlButton, GlLoadingIcon } from '@gitlab/ui'
import CiStatus from '~/vue_shared/components/ci_icon.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CiStatus,
    GlButton,
    GlLoadingIcon,
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
  methods: {
    onClickLinkedPipeline() {
      this.$root.$emit('bv::hide::tooltip', `js-linked-pipeline-${this.pipelineId}`);
      this.$emit('pipelineClicked')
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
        :id="`js-linked-pipeline-${pipelineId}`"
        @click="onClickLinkedPipeline"
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
      </gl-button>
    </div>
  </li>
</template>
