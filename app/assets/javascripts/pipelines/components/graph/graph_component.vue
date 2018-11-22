<script>
import _ from 'underscore';
import { GlLoadingIcon } from '@gitlab/ui';
import StageColumnComponent from './stage_column_component.vue';
import LinkedPipelinesColumn from 'ee/pipelines/components/graph/linked_pipelines_column.vue'; // eslint-disable-line import/order

export default {
  components: {
    LinkedPipelinesColumn,
    StageColumnComponent,
    GlLoadingIcon,
  },
  props: {
    isLoading: {
      type: Boolean,
      required: true,
    },
    pipeline: {
      type: Object,
      required: true,
    },
    triggered: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    tiggeredBy: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    triggeredByPipelines: {
      type: Array,
      required: false,
      default: [],
    },
    triggeredPipelines: {
      type: Array,
      required: false,
      default: [],
    }
  },

  computed: {
    graph() {
      return this.pipeline.details && this.pipeline.details.stages;
    },
    triggeredGraph() {
      return this.triggered && this.triggered.details && this.triggered.details.stages;
    },
    triggeredByGraph() {
      return this.triggeredBy && this.triggeredBy.details && this.triggeredBy.details.stages;
    },
    hasTriggered() {
      return this.triggeredPipelines.length > 0;
    },
    hasTriggeredBy() {
      return this.triggeredByPipelines.length > 0;
    },
    shouldRenderTriggeredPipeline() {
      return !this.isLoading && !_.isEmpty(this.triggered)
    },
    shouldRenderTriggeredByPipeline() {
      return !this.isLoading && !_.isEmpty(this.triggeredBy)
    },
  },
  methods: {
    capitalizeStageName(name) {
      const escapedName = _.escape(name);
      return escapedName.charAt(0).toUpperCase() + escapedName.slice(1);
    },

    isFirstColumn(index) {
      return index === 0;
    },

    stageConnectorClass(index, stage) {
      let className;

      // If it's the first stage column and only has one job
      if (index === 0 && stage.groups.length === 1) {
        className = 'no-margin';
      } else if (index > 0) {
        // If it is not the first column
        className = 'left-margin';
      }

      return className;
    },

    refreshPipelineGraph() {
      this.$emit('refreshPipelineGraph');
    },
  },
};
</script>
<template>
  <div class="build-content middle-block js-pipeline-graph">
    <div class="pipeline-visualization pipeline-graph pipeline-tab-content">
      <div class="text-center"><gl-loading-icon v-if="isLoading" :size="3" /></div>

      <ul
        v-if="shouldRenderTriggeredPipeline"
        class="stage-column-list"
      >
        triggered pipeline should open here 
      </ul>

      <linked-pipelines-column
        v-if="hasTriggeredBy"
        :linked-pipelines="triggeredByPipelines"
        :column-title="__('Upstream')"
        graph-position="left"
        @linkedPipelineClick="(pipeline) => $emit('onClickTriggeredBy', pipeline)"
      />

      <ul
        v-if="!isLoading"
        :class="{
          'has-linked-pipelines': hasTriggered || hasTriggeredBy,
        }"
        class="stage-column-list"
      >
        <stage-column-component
          v-for="(stage, index) in graph"
          :key="stage.name"
          :class="{
            'has-upstream': index === 0 && hasTriggeredBy,
            'has-downstream': index === graph.length - 1 && hasTriggered,
            'has-only-one-job': stage.groups.length === 1,
          }"
          :title="capitalizeStageName(stage.name)"
          :groups="stage.groups"
          :stage-connector-class="stageConnectorClass(index, stage)"
          :is-first-column="isFirstColumn(index)"
          :has-triggered-by="hasTriggeredBy"
          @refreshPipelineGraph="refreshPipelineGraph"
        />
      </ul>

      <linked-pipelines-column
        v-if="hasTriggered"
        :linked-pipelines="triggeredPipelines"
        :column-title="__('Downstream')"
        graph-position="right"
        @linkedPipelineClick="(pipeline) => $emit('onClickTriggered', pipeline)"
      />
    </div>
  </div>
</template>
