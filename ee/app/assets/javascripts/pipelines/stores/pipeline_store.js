import _ from 'underscore';
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
   * For the triggered pipelines adds the `isExpanded` key
   *
   * For the triggered_by pipeline adds the `isExpanded` key
   * and saves it as an array
   *
   * @param {Object} pipeline
   */
  storePipeline(pipeline = {}) {
    pipeline = Object.assign({}, data);
    super.storePipeline(pipeline);

    if (pipeline.triggered_by) {
      this.state.pipeline.triggered_by = [pipeline.triggered_by];

      this.parseTriggeredByPipelines(this.state.pipeline.triggered_by[0]);
    }

    if (pipeline.triggered && pipeline.triggered.length) {
      this.state.pipeline.triggered.forEach(el => this.parseTriggeredPipelines(el));
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
  parseTriggeredByPipelines(pipeline) {
    // keep old value in case it's opened because we're polling
    Vue.set(pipeline, 'isExpanded', pipeline.isExpanded || false);
    if (pipeline.triggered_by) {
      if (!_.isArray(pipeline.triggered_by)) {
        pipeline.triggered_by = [pipeline.triggered_by];
      }
      this.parseTriggeredByPipelines(pipeline.triggered_by[0]);
    }

    // if (pipeline.triggered && pipeline.triggered.length) {
    //   pipeline.triggered.forEach(el => this.parseTriggeredPipelines(el));
    // }
  }

  parsePipeline(pipeline) {}
  /**
   * Recursively parses the triggered pipelines
   * @param {Array} parentPipeline
   * @param {Object} pipeline
   */
  parseTriggeredPipelines(pipeline) {
    // keep old value in case it's opened because we're polling
    Vue.set(pipeline, 'isExpanded', pipeline.isExpanded || false);

    if (pipeline.triggered && pipeline.triggered.length > 0) {
      pipeline.triggered.forEach(el => this.parseTriggeredPipelines(el));
    }

    // if (pipeline.triggered_by) {
    //   pipeline.triggered_by = [pipeline.triggered_by];
    //   this.parseTriggeredByPipelines(pipeline.triggered_by[0]);
    // }
  }

  /**
   * Recursively resets all triggered by pipelines
   *
   * @param {Object} pipeline
   */
  resetTriggeredByPipeline(parentPipeline, pipeline) {
    parentPipeline.triggered_by.forEach(el => this.closePipeline(el));

    if (pipeline.triggered_by && pipeline.triggered_by) {
      this.resetTriggeredByPipeline(pipeline, pipeline.triggered_by);
    }
  }

  /**
   * Opens the clicked pipeline and closes all other ones.
   * @param {Object} pipeline
   */
  openTriggeredByPipeline(parentPipeline, pipeline) {
    // first we need to reset all triggeredBy pipelines
    this.resetTriggeredByPipeline(parentPipeline, pipeline);

    this.openPipeline(pipeline);
  }

  /**
   * On click, will close the given pipeline and all nested triggered by pipelines
   *
   * @param {Object} pipeline
   */
  closeTriggeredByPipeline(pipeline) {
    this.closePipeline(pipeline);

    if (pipeline.triggered_by && pipeline.triggered_by.length) {
      pipeline.triggered_by.forEach(triggeredBy => this.closeTriggeredByPipeline(triggeredBy));
    }
  }
  /**
   * On click, will close the given pipeline and all the nested triggered ones
   * @param {Object} pipeline
   */
  closeTriggeredPipeline(pipeline) {
    this.closePipeline(pipeline);

    if (pipeline.triggered && pipeline.triggered.length) {
      pipeline.triggered.forEach(triggered => this.closeTriggeredPipeline(triggered));
    }
  }

  /**
   * Utility function, Closes the given pipeline
   * @param {Object} pipeline
   */
  closePipeline(pipeline) {
    Vue.set(pipeline, 'isExpanded', false);
  }

  /**
   * Utility function, Opens the given pipeline
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
  openTriggeredPipeline(parentPipeline, pipeline) {
    this.resetTriggeredPipelines(parentPipeline, pipeline);
    this.openPipeline(pipeline);
  }

  /**
   * Recursively closes all triggered pipelines for the given one.
   *
   * @param {Object} pipeline
   */
  resetTriggeredPipelines(parentPipeline, pipeline) {
    parentPipeline.triggered.forEach(el => this.closePipeline(el));

    if (pipeline.triggered && pipeline.triggered.length) {
      pipeline.triggered.forEach(el => this.resetTriggeredPipelines(pipeline, el));
    }
  }
}
