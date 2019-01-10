export default {
  methods: {
    /**
     * Called when a linked pipeline is clicked.
     *
     * If the pipeline is collapsed we will start polling it & we will reset the other pipelines.
     * If the pipeline is expanded we will close it.
     *
     * @param {String} method Method to fetch the pipeline
     * @param {String} storeKey Store property that will be updates
     * @param {String} resetStoreKey Store key for the visible pipeline that will need to be reset
     * @param {Object} pipeline The clicked pipeline
     */
    clickPipeline(parentPipeline, pipeline, openMethod, closeMethod) {
      if (!pipeline.isExpanded) {
        this.mediator.store[openMethod](parentPipeline, pipeline);
      } else {
        this.mediator.store[closeMethod](pipeline);
      }
    },
    clickTriggeredByPipeline(parentPipeline, pipeline) {
      this.clickPipeline(
        parentPipeline,
        pipeline,
        'openTriggeredByPipeline',
        'closeTriggeredByPipeline',
      );
    },
    clickTriggeredPipeline(parentPipeline, pipeline) {
      this.clickPipeline(
        parentPipeline,
        pipeline,
        'openTriggeredPipeline',
        'closeTriggeredPipeline',
      );
    },
  },
};
