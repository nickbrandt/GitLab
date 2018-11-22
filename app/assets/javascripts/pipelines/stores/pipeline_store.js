import data from './data';

export default class PipelineStore {
  constructor() {
    this.state = {};
    this.state.pipeline = {};

    // all the upstream/downstream collapsed pipelines
    this.state.triggeredPipelines = [];
    this.state.triggeredByPipelines = [];

    // Visible upstream/downstream pipelines
    this.state.triggered = {};
    this.state.triggeredBy = {};
  }

  storePipeline(pipeline = {}) {
    // delete
    pipeline = data;

    this.state.pipeline = pipeline;
    if (pipeline.triggered.length) {
      this.state.triggeredPipelines = pipeline.triggered.map(triggered => PipelineStore.parsePipeline(triggered));
    }

    if (pipeline.triggered_by !== null) {
      this.state.triggeredByPipelines = [PipelineStore.parsePipeline(pipeline.triggered_by)];
    }
  }
  /**
   * Adds isLoading and collpased keys to the given pipeline
   * 
   * @param {Object} pipeline 
   * @returns {Object}
   */
  static parsePipeline(pipeline) {
    return Object.assign({}, pipeline, { 
      collapsed: true,
      isLoading: false,
    });
  }

  updateStoreOnRequest(storeKey, pipeline) {
    this.state[storeKey] = this.state[storeKey].map((triggered) => {
      if (triggered.id === pipeline.id) {
        return Object.assign({}, triggered, { isLoading: true, collapsed: false });
      }
      return PipelineStore.parsePipeline(triggered);
    })
  }

  /**
   * Returns the upstream/downstream that matches the given ID
   * 
   * @param {Object} pipeline 
   * @returns {Object}
   */
  getPipeline(storeKey, pipelineId) {
    return this.state[storeKey].find(triggered => triggered.id === pipelineId)
  }

  /**
   * Resets collapsed and isLoading props for all triggered pipelines
   * Sets isLoading to true for the requested one.
   * 
   * @param {Object} pipeline 
   */
  requestTriggeredPipeline(pipeline) {
    this.updateStoreOnRequest('triggeredPipelines', pipeline);
  }

  /**
   * Updates loading state for the request pipeline
   * Updates the visible pipeline with the response
   * 
   * @param {Object} pipeline 
   * @param {Object} response 
   */
  receiveTriggeredPipelineSuccess(pipeline, response) {
    const requestedPipeline = this.getPipeline('triggeredPipelines', pipeline.id);
    requestedPipeline.isLoading = false;

    this.state.triggered = response;
  }

  /**
   * Resets the loading state + collpased state
   * Resets triggeredBy pipeline
   */
  receiveTriggeredPipelineError(pipeline) {
    const requestedPipeline = this.getPipeline('triggeredPipelines', pipeline.id);
    requestedPipeline.isLoading = false;
    requestedPipeline.collapsed = true;

    this.state.triggered = {};
  }

  /**
   * 
   * @param {Object} pipeline 
   */
  requestTriggeredByPipeline(pipeline) {
    this.updateStoreOnRequest('triggeredByPipelines', pipeline);
  }

  receiveTriggeredByPipelineSuccess(pipeline, response) {
    const requestedPipeline =  this.getPipeline('triggeredByPipelines', pipeline.id);
    requestedPipeline.isLoading = false;

    this.state.triggeredBy = response;
  }

  receiveTriggeredByPipelineError(pipeline) {
    const requestedPipeline =  this.getPipeline('triggeredByPipelines', pipeline.id);
    requestedPipeline.isLoading = false;
    requestedPipeline.collapsed = true;

    this.state.triggeredBy = {};
  }
}
