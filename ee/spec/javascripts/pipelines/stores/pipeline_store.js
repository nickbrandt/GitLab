import PipelineStore from 'ee/pipelines/stores/pipeline_store';
import pipelineWithTriggered from './pipeline_with_triggered.json';
import pipelineWithTriggeredBy from './pipeline_with_triggered_by.json';
import pipelineWithBoth from './pipeline_with_triggered_triggered_by.json';
import pipeline from './pipeline.json';

describe('EE Pipeline store', () => {
  let store;

  beforeEach(() => {
    store = new PipelineStore();
  });

  describe('storePipeline', () => {
    describe('triggeredPipelines ', () => {
      describe('with triggered pipelines', () => {
        it('saves parsed pipelines', () => {
          store.storePipeline(pipelineWithTriggered);

          expect(store.triggeredPipelines.length).toEqual(pipelineWithTriggered.triggered.length);
          expect(store.triggeredPipelines[0]).toEqual(
            Object.assign({}, pipelineWithTriggered.triggered[0], {
              isLoading: false,
              isCollpased: true,
            }),
          );
        });
      });

      describe('without triggered pipelines', () => {
        it('triggeredPipelines should be an empty array', () => {
          store.storePipeline({ triggered: [] });

          expect(store.triggeredPipelines).toEqual([]);
        });
      });
    });

    describe('triggeredByPipelines', () => {
      describe('with triggered_by pipeline', () => {
        store.storePipeline(pipelineWithTriggeredBy);

        expect(store.pipelineWithTriggeredBy.length).toEqual(1);
        expect(store.triggeredByPipelines[0]).toEqual(
          Object.assign({}, pipelineWithTriggeredBy.triggered_by, {
            isLoading: false,
            isCollpased: true,
          }),
        );
      });

      describe('without triggered_by pipeline', () => {
        it('triggeredByPipelines should be an empty array', () => {
          store.storePipeline({ triggered_by: null });

          expect(store.triggeredByPipelines).toEqual([]);
        });
      });
    });
  });

  describe('downstream', () => {
    beforeAll(() => {
      store.storePipeline(pipelineWithBoth);
    });

    describe('requestTriggeredPipeline', () => {
      beforeEach(() => {
        store.requestTriggeredPipeline(store.triggeredPipelines[0]);
      });

      it('sets isLoading to true for the requested pipeline', () => {
        expect(store.triggeredPipelines[0].isLoading).toEqual(true);
      });

      it('sets isExpanded to true for the requested pipeline', () => {
        expect(store.triggeredPipelines[0].isExpanded).toEqual(true);
      });

      it('sets isLoading to false for the other pipelines', () => {
        expect(store.triggeredPipelines[1].isLoading).toEqual(false);
      });

      it('sets isExpanded to false for the other pipelines', () => {
        expect(store.triggeredPipelines[1].isExpanded).toEqual(false);
      });
    });

    describe('receiveTriggeredPipelineSuccess', () => {
      it('updates the given pipeline and sets it as the visible one', () => {
        const receivedPipeline = store.triggeredPipelines[0];

        store.receiveTriggeredPipelineSuccess(receivedPipeline);

        expect(store.triggeredPipelines[0].isLoading).toEqual(false);
        expect(store.triggered).toEqual(receivedPipeline);
      });
    });

    describe('receiveTriggeredPipelineError', () => {
      it('resets the given pipeline and resets it as the visible one', () => {
        const receivedPipeline = store.triggeredPipelines[0];

        store.receiveTriggeredPipelineError(receivedPipeline);

        expect(store.triggeredPipelines[0].isLoading).toEqual(false);
        expect(store.triggeredPipelines[0].isExpanded).toEqual(false);

        expect(store.triggered).toEqual({});
      });
    });
  });

  describe('upstream', () => {
    describe('requestTriggeredByPipeline', () => {
      beforeEach(() => {
        store.requestTriggeredByPipeline(store.triggeredByPipelines[0]);
      });

      it('sets isLoading to true for the requested pipeline', () => {
        expect(store.triggeredByPipelines[0].isLoading).toEqual(true);
      });

      it('sets isExpanded to true for the requested pipeline', () => {
        expect(store.triggeredByPipelines[0].isExpanded).toEqual(true);
      });
    });

    describe('receiveTriggeredByPipelineSuccess', () => {
      it('updates the given pipeline and sets it as the visible one', () => {
        const receivedPipeline = store.triggeredByPipelines[0];

        store.receiveTriggeredByPipelineSuccess(receivedPipeline);

        expect(store.triggeredByPipelines[0].isLoading).toEqual(false);
        expect(store.triggeredBy).toEqual(receivedPipeline);
      });
    });

    describe('receiveTriggeredByPipelineError', () => {
      it('resets the given pipeline and resets it as the visible one', () => {
        const receivedPipeline = store.triggeredByPipelines[0];

        store.receiveTriggeredByPipelineError(receivedPipeline);

        expect(store.triggeredByPipelines[0].isLoading).toEqual(false);
        expect(store.triggeredByPipelines[0].isExpanded).toEqual(false);

        expect(store.triggeredBy).toEqual({});
      });
    });
  });

  describe('utils', () => {
    describe('parsePipeline', () => {
      let parsed;
      beforeAll(() => {
        parsed = PipelineStore.parsePipeline(pipeline);
      });

      it('adds isLoading key set to false', () => {
        expect(parsed.isLoading).toEqual(false);
      });

      it('adds isExpanded key set to false', () => {
        expect(parsed.isExpanded).toEqual(false);
      });
    });

    describe('getPipelineIndex', () => {
      beforeAll(() => {
        store.storePipeline(pipelineWithBoth);
      });

      it('returns the pipeline index for the provided pipeline and storeKey', () => {
        store.getPipelineIndex('triggeredPipelines', store.triggeredPipelines[1]).toEqual(1);
      });
    });

    describe('updateStoreOnRequest', () => {
      beforeAll(() => {
        store.storePipeline(pipelineWithBoth);
      });

      it('sets clicked pipeline isLoading to true', () => {
        store.updateStoreOnRequest('triggeredPipelines', store.triggeredPipelines[1]);

        expect(store.triggeredPipelines[1].isLoading).isLoading(true);
      });

      it('sets clicked pipeline isExpanded to true', () => {
        store.updateStoreOnRequest('triggeredPipelines', store.triggeredPipelines[1]);

        expect(store.triggeredPipelines[1].isExpanded).isLoading(true);
      });
    });

    describe('updatePipeline', () => {
      beforeAll(() => {
        store.storePipeline(pipelineWithBoth);

        store.updatePipeline(
          'triggeredPipelines',
          store.triggeredPipelines[1],
          { isLoading: true },
          'triggered',
          store.triggeredPipelines[1],
        );
      });

      it('updates the given pipeline in the correct array', () => {
        expect(store.triggeredPipelines[1].isLoading).toEqual(true);
        expect(store.triggered).toEqual(store.triggeredPipelines[1]);
      });

      it('updates the visible pipeline to the given value', () => {});
    });

    describe('closePipeline', () => {
      beforeAll(() => {
        store.storePipeline(pipelineWithBoth);
      });

      it('closes the given pipeline', () => {
        const clickedPipeline = store.triggeredPipelines[1];

        // open it first
        clickedPipeline.isExpanded = true;
        store.triggered = clickedPipeline;

        store.closePipeline('triggeredPipelines', clickedPipeline, 'triggered');

        expect(store.triggeredPipelines[1].isExpanded).toEqual(true);
        expect(store.triggered).toEqual({});
      });
    });
  });
});
