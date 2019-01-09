import CePipelineStore from '~/pipelines/stores/pipeline_store';
import pipelinesKeys from '../constants';

/**
 * Extends CE store with the logic to handle the upstream/downstream pipelines
 */
export default class PipelineStore extends CePipelineStore {
  constructor() {
    super();

    // Stores the dowsntream collapsed pipelines
    // with basic info sent in the main request
    this.state.triggeredPipelines = [];
    // Stores the upstream collapsed pipelines
    // with basic info sent in the main request
    this.state.triggeredByPipelines = [];

    // Visible downstream pipeline
    this.state.triggered = {};
    // Visible upstream pipeline
    this.state.triggeredBy = {};
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
    super.storePipeline(pipeline);

    if (pipeline.triggered && pipeline.triggered.length) {
      this.state.triggeredPipelines = pipeline.triggered.map(triggered => {
        // because we are polling we need to make sure we do not hijack user's clicks.
        const oldPipeline = this.state.triggeredPipelines.find(
          oldValue => oldValue.id === triggered.id,
        );

        return Object.assign({}, triggered, {
          isExpanded: oldPipeline ? oldPipeline.isExpanded : false,
          isLoading: oldPipeline ? oldPipeline.isLoading : false,
        });
      });
    }

    if (pipeline.triggered_by) {
      this.state.triggeredByPipelines = [
        Object.assign({}, pipeline.triggered_by, {
          isExpanded: this.state.triggeredByPipelines.length
            ? this.state.triggeredByPipelines[0].isExpanded
            : false,
          isLoading: this.state.triggeredByPipelines.length
            ? this.state.triggeredByPipelines[0].isLoading
            : false,
        }),
      ];
    }
  }

  //
  // Downstream pipeline's methods
  //

  /**
   * Called when the user clicks on a pipeline that was triggered by the main one.
   *
   * Resets isExpanded and isLoading props for all triggered (downstream) pipelines
   * Sets isLoading to true for the requested one.
   *
   * @param {Object} pipeline
   */
  requestTriggeredPipeline(pipeline) {
    this.updateStoreOnRequest(pipelinesKeys.triggeredPipelines, pipeline);
  }

  /**
   * Called when we receive success callback for the downstream pipeline requested.
   *
   * Updates loading state for the request pipeline
   * Updates the visible pipeline with the response
   *
   * @param {Object} pipeline
   * @param {Object} response
   */
  receiveTriggeredPipelineSuccess(pipeline, response) {
    this.updatePipeline(
      pipelinesKeys.triggeredPipelines,
      pipeline,
      { isLoading: false, isExpanded: true },
      pipelinesKeys.triggered,
      response,
    );
  }

  /**
   * Called when we receive an error callback for the downstream pipeline requested
   * Resets the loading state + collpased state
   * Resets triggered pipeline
   *
   * @param {Object} pipeline
   */
  receiveTriggeredPipelineError(pipeline) {
    this.updatePipeline(
      pipelinesKeys.triggeredPipelines,
      pipeline,
      { isLoading: false, isExpanded: false },
      pipelinesKeys.triggered,
      {},
    );
  }

  //
  // Upstream pipeline's methods
  //

  /**
   * Called when the user clicks on the pipeline that triggered the main one.
   *
   * Handle the request for the upstream pipeline
   * Updates the given pipeline with isLoading: true and isExpanded: true
   *
   * @param {Object} pipeline
   */
  requestTriggeredByPipeline(pipeline) {
    this.updateStoreOnRequest(pipelinesKeys.triggeredByPipelines, pipeline);
  }

  /**
   * Success callback for the upstream pipeline received
   *
   * @param {Object} pipeline
   * @param {Object} response
   */
  receiveTriggeredByPipelineSuccess(pipeline, response) {
    this.updatePipeline(
      pipelinesKeys.triggeredByPipelines,
      pipeline,
      { isLoading: false, isExpanded: true },
      pipelinesKeys.triggeredBy,
      response,
    );
  }

  /**
   * Error callback for the upstream callback
   * @param {Object} pipeline
   */
  receiveTriggeredByPipelineError(pipeline) {
    this.updatePipeline(
      pipelinesKeys.triggeredByPipelines,
      pipeline,
      { isLoading: false, isExpanded: false },
      pipelinesKeys.triggeredBy,
      {},
    );
  }

  //
  // Common utils between upstream & dowsntream pipelines
  //

  /**
   * Adds isLoading and isCollpased keys to the given pipeline
   *
   * Used to know when to render the spinning icon
   * and the blue background when the pipeline is expanded.
   *
   * @param {Object} pipeline
   * @returns {Object}
   */
  static parsePipeline(pipeline) {
    return Object.assign({}, pipeline, {
      isExpanded: false,
      isLoading: false,
    });
  }

  /**
   * Returns the index of the upstream/downstream that matches the given ID
   *
   * @param {Object} pipeline
   * @returns {Number}
   */
  getPipelineIndex(storeKey, pipelineId) {
    return this.state[storeKey].findIndex(triggered => triggered.id === pipelineId);
  }

  /**
   * Updates the pipelines to reflect which one was requested.
   * It sets isLoading to true and isExpanded to false
   *
   * @param {String} storeKey which property to update: `triggeredPipelines|triggeredByPipelines`
   * @param {Object} pipeline the requested pipeline
   */
  updateStoreOnRequest(storeKey, pipeline) {
    this.state[storeKey] = this.state[storeKey].map(triggered => {
      if (triggered.id === pipeline.id) {
        return Object.assign({}, triggered, { isLoading: true, isExpanded: true });
      }
      // reset the others, in case another was one opened
      return PipelineStore.parsePipeline(triggered);
    });
  }

  /**
   * Updates a single pipeline with the new props and the visible pipeline
   * Used for success and error callbacks for both upstream and downstream requests.
   *
   * @param {String} storeKey Which array needs to be updated: `triggeredPipelines|triggeredByPipelines`
   * @param {Object} pipeline Which pipeline should be updated
   * @param {Object} props The new properties to be updated for the given pipeline
   * @param {String} visiblePipelineKey Which visible pipeline needs to be updated: `triggered|triggeredBy`
   * @param {Object} visiblePipeline The new visible pipeline value
   */
  updatePipeline(storeKey, pipeline, props, visiblePipelineKey, visiblePipeline = {}) {
    this.state[storeKey].splice(
      this.getPipelineIndex(storeKey, pipeline.id),
      1,
      Object.assign({}, pipeline, props),
    );

    this.state[visiblePipelineKey] = visiblePipeline;
  }

  /**
   * When the user clicks on a non collapsed pipeline we need to close it
   *
   * @param {String} storeKey  Which array needs to be updated: `triggeredPipelines|triggeredByPipelines`
   * @param {Object} pipeline Which pipeline should be updated
   * @param {String} visiblePipelineKey Which visible pipeline needs to be updated: `triggered|triggeredBy`
   */
  closePipeline(storeKey, pipeline, visiblePipelineKey) {
    this.updatePipeline(
      storeKey,
      pipeline,
      {
        isLoading: false,
        isExpanded: false,
      },
      visiblePipelineKey,
      {},
    );
  }
}
