import Vue from 'vue';
import pipelineComponent from '~/vue_merge_request_widget/components/mr_widget_pipeline.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import mockData from 'ee_spec/vue_mr_widget/mock_data';
import mockLinkedPipelines from 'ee_spec/pipelines/graph/linked_pipelines_mock_data';

describe('MRWidgetPipeline', () => {
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(pipelineComponent);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('when upstream pipelines are passed', () => {
      beforeEach(() => {
        vm = mountComponent(Component, {
          pipeline: Object.assign({}, mockData.pipeline, {
            triggered_by: mockLinkedPipelines.triggered_by,
          }),
          hasCi: true,
          ciStatus: 'success',
          troubleshootingDocsPath: 'help',
        });
      });

      it('should coerce triggeredBy into a collection', () => {
        expect(vm.triggeredBy.length).toBe(1);
      });

      it('should render the linked pipelines mini list', () => {
        expect(vm.$el.querySelector('.linked-pipeline-mini-list.is-upstream')).not.toBeNull();
      });
    });

    describe('when downstream pipelines are passed', () => {
      beforeEach(() => {
        vm = mountComponent(Component, {
          pipeline: Object.assign({}, mockData.pipeline, {
            triggered: mockLinkedPipelines.triggered,
          }),
          hasCi: true,
          ciStatus: 'success',
          troubleshootingDocsPath: 'help',
        });
      });

      it('should render the linked pipelines mini list', () => {
        expect(vm.$el.querySelector('.linked-pipeline-mini-list.is-downstream')).not.toBeNull();
      });
    });
  });
});
