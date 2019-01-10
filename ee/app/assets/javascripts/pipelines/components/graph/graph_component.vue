<script>
import _ from 'underscore';
import { GlLoadingIcon } from '@gitlab/ui';
import LinkedPipelinesColumn from 'ee/pipelines/components/graph/linked_pipelines_column.vue';
import EEGraphMixin from 'ee/pipelines/mixins/graph_component_mixin';
import StageColumnComponent from '~/pipelines/components/graph/stage_column_component.vue';

export default {
  components: {
    LinkedPipelinesColumn,
    StageColumnComponent,
    GlLoadingIcon,
  },
  mixins: [EEGraphMixin],
  props: {
    isLoading: {
      type: Boolean,
      required: true,
    },
    pipeline: {
      type: Object,
      required: true,
    },
  },
  computed: {
    graph() {
      return this.pipeline.details && this.pipeline.details.stages;
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
    hasOnlyOneJob(stage) {
      return stage.groups.length === 1;
    },
  },
};
</script>
<template>
  <div class="build-content middle-block js-pipeline-graph">
    <div class="pipeline-visualization pipeline-graph pipeline-tab-content">
      <div class="text-center"><gl-loading-icon v-if="isLoading" :size="3" /></div>

      <ul v-if="shouldRenderTriggeredByPipeline" class="d-inline-block upstream-pipeline align-top">
        <stage-column-component
          v-for="(stage, indexUpstream) in triggeredByGraph"
          :key="stage.name"
          :class="{
            'has-only-one-job': hasOnlyOneJob(stage),
          }"
          :title="capitalizeStageName(stage.name)"
          :groups="stage.groups"
          :stage-connector-class="stageConnectorClass(indexUpstream, stage)"
          :is-first-column="isFirstColumn(indexUpstream)"
          @refreshPipelineGraph="refreshTriggeredByPipelineGraph"
        />
      </ul>

      <linked-pipelines-column
        v-if="hasTriggeredBy"
        :linked-pipelines="triggeredByPipelines"
        :column-title="__('Upstream')"
        graph-position="left"
        @linkedPipelineClick="pipeline => $emit('onClickTriggeredBy', pipeline)"
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

      <ul
        v-if="shouldRenderTriggeredPipeline"
        class="d-inline-block downstream-pipeline position-relative align-top"
        :style="{ 'margin-top': marginTop }"
      >
        <stage-column-component
          v-for="(stage, indexDownstream) in triggeredGraph"
          :key="stage.name"
          :class="{
            'has-only-one-job': hasOnlyOneJob(stage),
          }"
          :title="capitalizeStageName(stage.name)"
          :groups="stage.groups"
          :stage-connector-class="stageConnectorClass(indexDownstream, stage)"
          :is-first-column="isFirstColumn(indexDownstream)"
          @refreshPipelineGraph="refreshTriggeredPipelineGraph"
        />
      </ul>
    </div>
  </div>
</template>
