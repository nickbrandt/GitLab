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

  collapseTriggeredPipeline(pipeline) {
    const requestedPipeline = this.getPipelineIndex('triggeredPipelines', pipeline.id);

    this.state.triggeredPipelines.splice(requestedPipeline, 1, Object.assign({}, pipeline, { collapsed: true }))
  }

  resetTriggered(storeKey) {
    this.state[storeKey] = {};
  }

  collapsePipeline(storeKey, pipeline) {
    const requestedPipeline = this.getPipelineIndex(storeKey, pipeline.id);

    this.state[storeKey].splice(requestedPipeline, 1, Object.assign({}, pipeline, { collapsed: true }))
  }

  /**
   * Updates the pipelines to reflect which one was just requested.
   * 
   * @param {*} storeKey 
   * @param {*} pipeline 
   */
  updateStoreOnRequest(storeKey, pipeline) {
    this.state[storeKey] = this.state[storeKey].map((triggered) => {
      debugger;
      if (triggered.id === pipeline.id) {
        return Object.assign({}, triggered, { isLoading: true, collapsed: false });
      }

      return PipelineStore.parsePipeline(triggered);
    });
    debugger;
  }

  /**
   * Returns the index of THE upstream/downstream that matches the given ID
   * 
   * @param {Object} pipeline 
   * @returns {Number}
   */
  getPipelineIndex(storeKey, pipelineId) {
    return this.state[storeKey].indexOf(triggered => triggered.id === pipelineId)
  }

  /**
   * Resets collapsed and isLoading props for all triggered (downstream) pipelines
   * Sets isLoading to true for the requested one.
   * 
   * @param {Object} pipeline 
   */
  requestTriggeredPipeline(pipeline) {
    this.updateStoreOnRequest('triggeredPipelines', pipeline);
  }

  /**
   * Success callback for the downstream pipeline requested.
   * 
   * Updates loading state for the request pipeline
   * Updates the visible pipeline with the response
   * 
   * @param {Object} pipeline 
   * @param {Object} response 
   */
  receiveTriggeredPipelineSuccess(pipeline, response) {
    const requestedPipeline = this.getPipelineIndex('triggeredPipelines', pipeline.id);

    this.state.triggeredPipelines.splice(requestedPipeline, 1, Object.assign({}, pipeline, { isLoading: false }))
    this.state.triggered = response;
  }

  /**
   * Error callback for the downstream pipeline requested
   * Resets the loading state + collpased state
   * Resets triggeredBy pipeline
   */
  receiveTriggeredPipelineError(pipeline) {
    const requestedPipeline = this.getPipelineIndex('triggeredPipelines', pipeline.id);
   
    this.state.triggeredPipelines.splice(requestedPipeline, 1, Object.assign({}, pipeline, { isLoading: false, collapsed: true }))
    this.state.triggered = {};
  }

  /**
   * Handle the request for the upstream pipeline
   * Updates the given pipeline with isLoading: true and collapsed: false
   * @param {Object} pipeline 
   */
  requestTriggeredByPipeline(pipeline) {
    this.updateStoreOnRequest('triggeredByPipelines', pipeline);
  }

  /**
   * Success callback for the upstream pipeline received
   * 
   * @param {Object} pipeline 
   * @param {Object} response 
   */
  receiveTriggeredByPipelineSuccess(pipeline, response) {
    const requestedPipeline = this.getPipelineIndex('triggeredByPipelines', pipeline.id);

    this.state.triggeredByPipelines.splice(requestedPipeline, 1, Object.assign({}, pipeline, { isLoading: false }))
    this.state.triggeredBy = response;
  }

  /**
   * Error callback for the upstream callback
   * @param {Object} pipeline 
   */
  receiveTriggeredByPipelineError(pipeline) {
    const requestedPipeline =  this.getPipelineIndex('triggeredByPipelines', pipeline.id);
    
    this.state.triggeredByPipelines.splice(requestedPipeline, 1, Object.assign({}, pipeline, { isLoading: false, collapsed: true }))


    this.state.triggeredBy = {};
  }
}
