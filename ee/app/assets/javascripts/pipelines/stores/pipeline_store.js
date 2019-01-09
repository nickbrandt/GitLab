import CePipelineStore from '~/pipelines/stores/pipeline_store';
import data from '../mock.json';
import Vue from 'vue';

/**
 * Extends CE store with the logic to handle the upstream/downstream pipelines
 */
export default class PipelineStore extends CePipelineStore {
  constructor() {
    super();
  }

  /**
   * For the triggered pipelines, parses them to add `isLoading` and `isExpanded` keys
   *
   * For the triggered_by pipeline, parsed the object to add `isLoading` and `isExpanded` keys
   * and saves it as an array
   *
   * @param {Object} pipeline
   */
  storePipeline(pipeline = {}) {
    pipeline = Object.assign({}, data);
    super.storePipeline(pipeline);

    if (pipeline.triggered_by) {
      this.state.pipeline.triggered_by = [pipeline.triggered_by];
      this.parseTriggeredByPipelines(this.state.pipeline, pipeline.triggered_by);
    }

    if (pipeline.triggered && pipeline.triggered.length) {
      this.state.triggeredPipelines = pipeline.triggered.map(triggered =>
        this.parseTriggeredPipelines(this.state.pipeline, triggered),
      );
    }
  }

  /**
   * Recursiverly parses the triggered by pipelines.
   *
   * Sets triggered_by as an array, there is always only 1 triggered_by pipeline.
   * Adds key `isExpanding`
   * Keeps old isExpading value due to polling
   *
   * @param {Array} parentPipeline
   * @param {Object} pipeline
   */
  parseTriggeredByPipelines(parentPipeline, pipeline) {
    // keep old value in case it's opened because we're polling
    Vue.set(pipeline, 'isExpanded', pipeline.isExpanded || false);

    if (pipeline.triggered_by) {
      pipeline.triggered_by = [pipeline.triggered_by];
      this.parseTriggeredByPipelines(pipeline, pipeline.triggered_by);
    }
  }
  /**
   * Recursively parses the triggered pipelines
   * @param {Array} parentPipeline
   * @param {Object} pipeline
   */
  parseTriggeredPipelines(parentPipeline, pipeline) {
    // keep old value in case it's opened because we're polling
    Vue.set(pipeline, 'isExpanded', pipeline.isExpanded || false);

    if (pipeline.triggered && pipeline.triggered.length > 0) {
      pipeline.triggered.forEach(el => this.parseTriggeredPipelines(el));
    }
  }

  /**
   * Recursively resets all triggered by pipelines
   *
   *
   * @param {Object} pipeline
   */
  resetTriggeredByPipeline(pipeline) {
    this.closePipeline(pipeline);

    if (pipeline.triggered_by && pipeline.triggered_by) {
      this.resetTriggeredByPipeline(pipeline.triggered_by);
    }
  }

  /**
   * Opens the clicked pipeline and closes all other ones.
   * @param {Object} pipeline
   */
  openTriggeredByPipeline(pipeline) {
    // first we need to reset all triggeredBy pipelines
    this.resetTriggeredByPipeline(pipeline);

    this.openPipeline(pipeline);
  }

  /**
   * Closes the given pipeline
   * @param {Object} pipeline
   */
  closePipeline(pipeline) {
    Vue.set(pipeline, 'isExpanded', false);
  }

  /**
   * Closes the given pipeline
   * @param {Object} pipeline
   */
  openPipeline(pipeline) {
    Vue.set(pipeline, 'isExpanded', true);
  }
  /**
   * Opens the clicked triggered pipeline and closes all other ones.
   *
   * @param {Object} pipeline
   */
  openTriggeredPipeline(pipeline) {
    this.resetTriggeredPipelines(pipeline);
    this.openPipeline(pipeline);
  }

  /**
   * Recursively closes all triggered pipelines for the given one.
   *
   * @param {Object} pipeline
   */
  resetTriggeredPipelines(pipeline) {
    this.closePipeline(pipeline);

    if (pipeline.triggered && pipeline.triggered.length) {
      pipeline.triggered.forEach(el => this.resetTriggeredPipelines(el));
    }
  }
}
