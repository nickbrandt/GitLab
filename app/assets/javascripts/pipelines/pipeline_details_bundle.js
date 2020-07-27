import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import pipelineGraph from './components/graph/graph_component.vue';
import Dag from './components/dag/dag.vue';
import GraphBundleMixin from './mixins/graph_pipeline_bundle_mixin';
import PipelinesMediator from './pipeline_details_mediator';
import TestReports from './components/test_reports/test_reports.vue';
import createTestReportsStore from './stores/test_reports';
import { createPipelineHeaderApp } from './pipeline_details_header';

Vue.use(Translate);

const createPipelinesDetailApp = mediator => {
  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-pipeline-graph-vue',
    components: {
      pipelineGraph,
    },
    mixins: [GraphBundleMixin],
    data() {
      return {
        mediator,
      };
    },
    render(createElement) {
      return createElement('pipeline-graph', {
        props: {
          isLoading: this.mediator.state.isLoading,
          pipeline: this.mediator.store.state.pipeline,
          mediator: this.mediator,
        },
        on: {
          refreshPipelineGraph: this.requestRefreshPipelineGraph,
          onResetTriggered: (parentPipeline, pipeline) =>
            this.resetTriggeredPipelines(parentPipeline, pipeline),
          onClickTriggeredBy: pipeline => this.clickTriggeredByPipeline(pipeline),
          onClickTriggered: pipeline => this.clickTriggeredPipeline(pipeline),
        },
      });
    },
  });
};

const createTestDetails = () => {
  if (!window.gon?.features?.junitPipelineView) {
    return;
  }

  const el = document.querySelector('#js-pipeline-tests-detail');
  const { summaryEndpoint, suiteEndpoint } = el?.dataset || {};

  const testReportsStore = createTestReportsStore({
    summaryEndpoint,
    suiteEndpoint,
  });

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      TestReports,
    },
    store: testReportsStore,
    render(createElement) {
      return createElement('test-reports');
    },
  });
};

const createDagApp = () => {
  if (!window.gon?.features?.dagPipelineTab) {
    return;
  }

  const el = document.querySelector('#js-pipeline-dag-vue');
  const { pipelineDataPath, emptySvgPath, dagDocPath } = el?.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      Dag,
    },
    render(createElement) {
      return createElement('dag', {
        props: {
          graphUrl: pipelineDataPath,
          emptySvgPath,
          dagDocPath,
        },
      });
    },
  });
};

export default () => {
  const { dataset } = document.querySelector('.js-pipeline-details-vue');
  const mediator = new PipelinesMediator({ endpoint: dataset.endpoint });
  mediator.fetchPipeline();

  createPipelinesDetailApp(mediator);
  createPipelineHeaderApp();
  createTestDetails();
  createDagApp();
};
