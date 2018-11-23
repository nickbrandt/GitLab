import Vue from 'vue';
import Flash from '~/flash';
import Translate from '~/vue_shared/translate';
import { __ } from '~/locale';
import PipelinesMediator from './pipeline_details_mediator';
import pipelineGraph from './components/graph/graph_component.vue';
import pipelineHeader from './components/header_component.vue';
import eventHub from './event_hub';

Vue.use(Translate);

export default () => {
  const { dataset } = document.querySelector('.js-pipeline-details-vue');

  const mediator = new PipelinesMediator({ endpoint: dataset.endpoint });

  mediator.fetchPipeline();

  // eslint-disable-next-line
  new Vue({
    el: '#js-pipeline-graph-vue',
    components: {
      pipelineGraph,
    },
    data() {
      return {
        mediator,
      };
    },
    methods: {
      requestRefreshPipelineGraph() {
        // When an action is clicked
        // (wether in the dropdown or in the main nodes, we refresh the big graph)
        this.mediator
          .refreshPipeline()
          .catch(() => Flash(__('An error occurred while making the request.')));
      },
      clickPipeline(method, storeKey, resetStoreKey, pipeline) {
        debugger;
        if (pipeline.collapsed) {
          this.mediator[method](pipeline);
        } else {
          this.mediator.store.closePipeline(storeKey, pipeline);
          this.mediator.store.resetTriggered(resetStoreKey)
        }
      },
      clickTriggered(triggered) {
        this.clickPipeline('fetchTriggeredPipeline', 'triggeredPipelines', 'triggered', triggered);
      },
      clickTriggeredBy(triggeredBy) {
        this.clickPipeline('fetchTriggeredByPipeline', 'triggeredByPipelines', 'triggeredBy', triggeredBy);
      }
    },
    render(createElement) {
      return createElement('pipeline-graph', {
        props: {
          isLoading: this.mediator.state.isLoading,
          pipeline: this.mediator.store.state.pipeline,
          triggeredPipelines: this.mediator.store.state.triggeredPipelines,
          triggered: this.mediator.store.state.triggered,
          triggeredByPipelines: this.mediator.store.state.triggeredByPipelines,
          triggeredBy: this.mediator.store.state.triggeredBy,
        },
        on: {
          refreshPipelineGraph: this.requestRefreshPipelineGraph,
          onClickTriggeredBy: (pipeline) => this.clickTriggeredBy(pipeline),
          onClickTriggered: (pipeline) => this.clickTriggered(pipeline)
        },
      });
    },
  });

  // eslint-disable-next-line
  new Vue({
    el: '#js-pipeline-header-vue',
    components: {
      pipelineHeader,
    },
    data() {
      return {
        mediator,
      };
    },
    created() {
      eventHub.$on('headerPostAction', this.postAction);
    },
    beforeDestroy() {
      eventHub.$off('headerPostAction', this.postAction);
    },
    methods: {
      postAction(action) {
        this.mediator.service
          .postAction(action.path)
          .then(() => this.mediator.refreshPipeline())
          .catch(() => Flash(__('An error occurred while making the request.')));
      },
    },
    render(createElement) {
      return createElement('pipeline-header', {
        props: {
          isLoading: this.mediator.state.isLoading,
          pipeline: this.mediator.store.state.pipeline,
        },
      });
    },
  });
};
