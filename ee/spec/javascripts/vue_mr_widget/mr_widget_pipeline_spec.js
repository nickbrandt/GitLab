import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import mockData from 'ee_spec/vue_mr_widget/mock_data';
import { trimText } from 'spec/helpers/text_helper';
import pipelineComponent from '~/vue_merge_request_widget/components/mr_widget_pipeline.vue';
import mockLinkedPipelines from '../vue_shared/components/linked_pipelines_mock_data';

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

  describe('for each type of pipeline', () => {
    let pipeline;

    beforeEach(() => {
      ({ pipeline } = JSON.parse(JSON.stringify(mockData)));

      pipeline.ref.tag = false;
      pipeline.ref.branch = false;
    });

    const factory = () => {
      vm = mountComponent(Component, {
        pipeline,
        hasCi: true,
        ciStatus: 'success',
        troubleshootingDocsPath: 'help',
        sourceBranchLink: mockData.source_branch_link,
      });
    };

    describe('for a merge train pipeline', () => {
      it('renders a pipeline widget that reads "Merge train pipeline <ID> <status> for <SHA>"', () => {
        pipeline.details.name = 'Merge train pipeline';
        pipeline.merge_request_event_type = 'merge_train';

        factory();

        const expected = `Merge train pipeline #${pipeline.id} ${pipeline.details.status.label} for ${pipeline.commit.short_id}`;
        const actual = trimText(vm.$el.querySelector('.js-pipeline-info-container').innerText);

        expect(actual).toBe(expected);
      });
    });

    describe('for a merged result pipeline', () => {
      it('renders a pipeline widget that reads "Merged result pipeline <ID> <status> for <SHA>"', () => {
        pipeline.details.name = 'Merged result pipeline';
        pipeline.merge_request_event_type = 'merged_result';

        factory();

        const expected = `Merged result pipeline #${pipeline.id} ${pipeline.details.status.label} for ${pipeline.commit.short_id}`;
        const actual = trimText(vm.$el.querySelector('.js-pipeline-info-container').innerText);

        expect(actual).toBe(expected);
      });
    });
  });
});
