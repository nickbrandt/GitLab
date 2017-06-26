<script>
import ciStatus from '../../../vue_shared/components/ci_icon.vue';
import tooltip from '../../../vue_shared/directives/tooltip';
import eventHub from '../../event_hub';

export default {
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
    type: {
      type: String,
      required: true,
    },
  },
  directives: {
    tooltip,
  },
  components: {
    ciStatus,
  },
  computed: {
    tooltipText() {
      return `${this.projectName} - ${this.pipelineStatus.label}`;
    },
  },

  methods: {
    expand() {
      eventHub.$emit('expandNode', { 
        type: this.type,
        id: this.pipelineId,
      });
    }
  }
};
</script>

<template>
  <li class="linked-pipeline build">
    <div class="curve"></div>
    <div>
      <div 
        style="background: blue; width: 10px; height: 40px;"
        @click="expand"></div>
      <a
        v-tooltip
        class="linked-pipeline-content"
        :href="pipelinePath"
        :title="tooltipText"
        data-container="body">
        <span class="linked-pipeline-status ci-status-text">
          <ci-status :status="pipelineStatus"/>
        </span>
        <span class="linked-pipeline-project-name">{{ projectName }}</span>
        <span class="project-name-pipeline-id-separator">&#8226;</span>
        <span class="linked-pipeline-id">#{{ pipelineId }}</span>
      </a>
    </div>
  </li>
</template>
