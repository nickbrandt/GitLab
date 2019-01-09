import keys from '../constants';

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
    clickPipeline(pipeline, method) {
      debugger;
      if (!pipeline.isExpanded) {
        this.mediator.store[method](pipeline);
      } else {
        this.mediator.store.closePipeline(pipeline);
      }
    },
    clickTriggeredByPipeline(pipeline) {
      this.clickPipeline(pipeline, 'openTriggeredByPipeline');
    },
    clickTriggeredPipeline(pipeline) {
      this.clickPipeline(pipeline, 'openTriggeredPipeline');
    },
  },
};
