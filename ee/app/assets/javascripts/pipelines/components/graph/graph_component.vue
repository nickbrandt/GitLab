<script>
import _ from 'underscore';
import { GlLoadingIcon } from '@gitlab/ui';
import LinkedPipelinesColumn from 'ee/pipelines/components/graph/linked_pipelines_column.vue';
import EEGraphMixin from 'ee/pipelines/mixins/graph_component_mixin';
import StageColumnComponent from '~/pipelines/components/graph/stage_column_component.vue';
import GraphEEMixin from 'ee/pipelines/mixins/graph_pipeline_bundle_mixin'; // eslint-disable-line import/order

export default {
  name: 'PipelineGraph',
  components: {
    LinkedPipelinesColumn,
    StageColumnComponent,
    GlLoadingIcon,
  },
  mixins: [EEGraphMixin, GraphEEMixin],
  props: {
    isLoading: {
      type: Boolean,
      required: true,
    },
    pipeline: {
      type: Object,
      required: true,
    },
    isLinkedPipeline: {
      type: Boolean,
      default: false,
    },
    mediator: {
      type: Object,
      required: true,
    },
    type: {
      type: String,
      required: false,
      default: 'main',
    },
  },
  computed: {
    graph() {
      return this.pipeline.details && this.pipeline.details.stages;
    },
  },
  methods: {
    // todo filipa: move this into a ce mixin
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
    hasOnlyOneJob(stage) {
      return stage.groups.length === 1;
    },
  },
};
</script>
<template>
  <div class="build-content middle-block js-pipeline-graph">
    <div
      class="pipeline-visualization pipeline-graph"
      :class="{ 'pipeline-tab-content': !isLinkedPipeline }"
    >
      <div class="text-center" v-if="isLoading"><gl-loading-icon :size="3" /></div>

      <pipeline-graph
        type="upstream"
        class="d-inline-block upstream-pipeline"
        v-if="expandedTriggeredBy && type !== 'downstream'"
        :is-loading="false"
        :pipeline="expandedTriggeredBy"
        :is-linked-pipeline="true"
        :mediator="mediator"
        @onClickTriggeredBy="
          (parentPipeline, pipeline) => this.clickTriggeredByPipeline(parentPipeline, pipeline)
        "
      />

      <linked-pipelines-column
        v-if="hasTriggeredBy"
        :linked-pipelines="triggeredByPipelines"
        :column-title="__('Upstream')"
        graph-position="left"
        @linkedPipelineClick="pipeline => $emit('onClickTriggeredBy', this.pipeline, pipeline)"
      />

      <ul
        v-if="!isLoading"
        :class="{
          'has-linked-pipelines': hasTriggered || hasTriggeredBy,
        }"
        class="stage-column-list align-top"
      >
        <stage-column-component
          v-for="(stage, index) in graph"
          :key="stage.name"
          :class="{
            'has-upstream': index === 0 && hasTriggeredBy,
            'has-downstream': index === graph.length - 1 && hasTriggered,
            'has-only-one-job': hasOnlyOneJob(stage),
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
        @linkedPipelineClick="handleClickedDownstream"
      />

      <pipeline-graph
        type="downstream"
        class="d-inline-block"
        v-if="expandedTriggered && type !== 'upstream'"
        :is-loading="false"
        :pipeline="expandedTriggered"
        :is-linked-pipeline="true"
        :style="{ 'margin-top': marginTop }"
        @onClickTriggered="
          (parentPipeline, pipeline) => this.clickTriggeredPipeline(parentPipeline, pipeline)
        "
        :mediator="mediator"
      />
    </div>
  </div>
</template>
