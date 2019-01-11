<script>
import _ from 'underscore';
import { GlLoadingIcon } from '@gitlab/ui';
import StageColumnComponent from '~/pipelines/components/graph/stage_column_component.vue';
import GraphMixin from '~/pipelines/mixins/graph_component_mixin';
import LinkedPipelinesColumn from 'ee/pipelines/components/graph/linked_pipelines_column.vue';
import GraphEEMixin from 'ee/pipelines/mixins/graph_pipeline_bundle_mixin';

export default {
  name: 'PipelineGraph',
  components: {
    StageColumnComponent,
    GlLoadingIcon,
    LinkedPipelinesColumn,
  },
  mixins: [GraphMixin, GraphEEMixin],
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
  upstream: 'upstream',
  downstream: 'downstream',
  data() {
    return {
      triggeredTopIndex: 1,
    };
  },
  computed: {
    hasTriggeredBy() {
      return (
        this.type !== this.$options.downstream &&
        this.pipeline.triggered_by &&
        this.pipeline.triggered_by != null
      );
    },
    triggeredByPipelines() {
      return this.pipeline.triggered_by;
    },
    hasTriggered() {
      return (
        this.type !== this.$options.upstream &&
        this.pipeline.triggered &&
        this.pipeline.triggered.length > 0
      );
    },
    triggeredPipelines() {
      return this.pipeline.triggered;
    },
    expandedTriggeredBy() {
      return (
        this.pipeline.triggered_by &&
        _.isArray(this.pipeline.triggered_by) &&
        this.pipeline.triggered_by.find(el => el.isExpanded)
      );
    },
    expandedTriggered() {
      return this.pipeline.triggered && this.pipeline.triggered.find(el => el.isExpanded);
    },

    /**
     * Calculates the margin top of the clicked downstream pipeline by
     * adding the height of each linked pipeline and the margin
     */
    marginTop() {
      return `${this.triggeredTopIndex * 52}px`;
    },
  },
  methods: {
    handleClickedDownstream(pipeline, clickedIndex) {
      this.triggeredTopIndex = clickedIndex;
      this.$emit('onClickTriggered', this.pipeline, pipeline);
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
      <div v-if="isLoading" class="m-auto"><gl-loading-icon :size="3" /></div>

      <pipeline-graph
        v-if="type !== $options.downstream && expandedTriggeredBy"
        type="upstream"
        class="d-inline-block upstream-pipeline"
        :class="`js-upstream-pipeline-${expandedTriggeredBy.id}`"
        :is-loading="false"
        :pipeline="expandedTriggeredBy"
        :is-linked-pipeline="true"
        :mediator="mediator"
        @onClickTriggeredBy="
          (parentPipeline, pipeline) => clickTriggeredByPipeline(parentPipeline, pipeline)
        "
        @refreshPipelineGraph="requestRefreshPipelineGraph"
      />

      <linked-pipelines-column
        v-if="hasTriggeredBy"
        :linked-pipelines="triggeredByPipelines"
        :column-title="__('Upstream')"
        graph-position="left"
        @linkedPipelineClick="
          linkedPipeline => $emit('onClickTriggeredBy', pipeline, linkedPipeline)
        "
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
        v-if="type !== $options.upstream && expandedTriggered"
        type="downstream"
        class="d-inline-block"
        :class="`js-downstream-pipeline-${expandedTriggered.id}`"
        :is-loading="false"
        :pipeline="expandedTriggered"
        :is-linked-pipeline="true"
        :style="{ 'margin-top': marginTop }"
        :mediator="mediator"
        @onClickTriggered="
          (parentPipeline, pipeline) => clickTriggeredPipeline(parentPipeline, pipeline)
        "
        @refreshPipelineGraph="requestRefreshPipelineGraph"
      />
    </div>
  </div>
</template>
