<script>
import LinkedPipeline from './linked_pipeline.vue';

export default {
  components: {
    LinkedPipeline,
  },
  props: {
    columnTitle: {
      type: String,
      required: true,
    },
    linkedPipelines: {
      type: Array,
      required: true,
    },
    graphPosition: {
      type: String,
      required: true,
    },
  },
  computed: {
    columnClass() {
      return `graph-position-${this.graphPosition}`;
    },
    connectorPosition() {
      return `connector-${this.graphPosition}`;
    }
  },
};
</script>

<template>
  <div :class="columnClass" class="stage-column linked-pipelines-column">
    <div class="stage-name linked-pipelines-column-title">{{ columnTitle }}</div>
    <div class="cross-project-triangle"></div>
    <ul>
      <linked-pipeline
        v-for="(pipeline, index) in linkedPipelines"
        :key="pipeline.id"
        :class="[connectorPosition, {
          'flat-connector-before': index === 0 && graphPosition === 'right',
          'active': !pipeline.collapsed || pipeline.isLoading
        }]"
        :pipeline-id="pipeline.id"
        :project-name="pipeline.project.name"
        :pipeline-status="pipeline.details.status"
        :is-loading="pipeline.isLoading"
        @pipelineClicked="$emit('linkedPipelineClick', pipeline)"
      />
    </ul>
  </div>
</template>
