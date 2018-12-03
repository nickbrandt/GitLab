import CePipelineMediator from '~/pipelines/pipeline_details_mediator';
import createFlash from '~/flash';
import Poll from '~/lib/utils/poll';
import { __ } from '~/locale';
import PipelineService from 'ee/pipelines/services/pipeline_service';

/**
 * Extends CE mediator with the logic to handle the upstream/downstream pipelines
 */
export default class EePipelineMediator extends CePipelineMediator {
  /**
   * Requests the clicked downstream pipeline pipeline
   *
   * @param {Object} pipeline
   */
  fetchTriggeredPipeline(pipeline) {
    if (this.pollTriggered) {
      this.pollTriggered.stop();

      this.pollTriggered = null;
    }

    this.store.requestTriggeredPipeline(pipeline);

    this.pollTriggered = new Poll({
      resource: PipelineService,
      method: 'getUpstreamDownstream',
      data: pipeline.path,
      successCallback: ({ data }) => this.store.receiveTriggeredPipelineSuccess(pipeline, data),
      errorCallback: () => {
        this.store.receiveTriggeredPipelineError(pipeline);
        createFlash(
          __('An error occured while fetching this downstream pipeline. Please try again'),
        );
      },
    });

    this.pollTriggered.makeRequest();
  }

  refreshTriggeredPipelineGraph() {
    this.pollTriggered.stop();
    this.pollTriggered.restart();
  }

  /**
   * Requests the clicked upstream pipeline pipeline
   * @param {*} pipeline
   */
  fetchTriggeredByPipeline(pipeline) {
    if (this.pollTriggeredBy) {
      this.pollTriggeredBy.stop();

      this.pollTriggeredBy = null;
    }

    this.store.requestTriggeredByPipeline(pipeline);

    this.pollTriggeredBy = new Poll({
      resource: PipelineService,
      method: 'getUpstreamDownstream',
      data: pipeline.path,
      successCallback: ({ data }) => this.store.receiveTriggeredByPipelineSuccess(pipeline, data),
      errorCallback: () => {
        this.store.receiveTriggeredByPipelineError(pipeline);
        createFlash(__('An error occured while fetching this upstream pipeline. Please try again'));
      },
    });

    this.pollTriggeredBy.makeRequest();
  }

  refreshTriggeredByPipelineGraph() {
    this.pollTriggeredBy.stop();
    this.pollTriggeredBy.restart();
  }

  resetPipeline(storeKey, pipeline, resetStoreKey, pollKey) {
    this[pollKey].stop();
    this.store.closePipeline(storeKey, pipeline, resetStoreKey);
  }
}
