import { mount } from '@vue/test-utils';
import mockData from 'ee_jest/vue_mr_widget/mock_data';
import { trimText } from 'jest/helpers/text_helper';
import pipelineComponent from '~/vue_merge_request_widget/components/mr_widget_pipeline.vue';
import mockLinkedPipelines from '../vue_shared/components/linked_pipelines_mock_data';

describe('MRWidgetPipeline', () => {
  let wrapper;

  function createComponent(pipeline) {
    wrapper = mount(pipelineComponent, {
      propsData: {
        pipeline,
        pipelineCoverageDelta: undefined,
        hasCi: true,
        ciStatus: 'success',
        sourceBranchLink: undefined,
        sourceBranch: undefined,
        troubleshootingDocsPath: 'help',
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('when upstream pipelines are passed', () => {
      beforeEach(() => {
        const pipeline = { ...mockData.pipeline, triggered_by: mockLinkedPipelines.triggered_by };

        createComponent(pipeline);
      });

      it('should coerce triggeredBy into a collection', () => {
        expect(wrapper.vm.triggeredBy).toHaveLength(1);
      });

      it('should render the linked pipelines mini list', () => {
        expect(wrapper.find('.linked-pipeline-mini-list.is-upstream').exists()).toBe(true);
      });
    });

    describe('when downstream pipelines are passed', () => {
      beforeEach(() => {
        const pipeline = { ...mockData.pipeline, triggered: mockLinkedPipelines.triggered };

        createComponent(pipeline);
      });

      it('should render the linked pipelines mini list', () => {
        expect(wrapper.find('.linked-pipeline-mini-list.is-downstream').exists()).toBe(true);
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

    describe('for a merge train pipeline', () => {
      it('renders a pipeline widget that reads "Merge train pipeline <ID> <status> for <SHA>"', () => {
        pipeline.details.name = 'Merge train pipeline';
        pipeline.merge_request_event_type = 'merge_train';

        createComponent(pipeline);

        const expected = `Merge train pipeline #${pipeline.id} ${pipeline.details.status.label} for ${pipeline.commit.short_id}`;
        const actual = trimText(wrapper.find('.js-pipeline-info-container').text());

        expect(actual).toBe(expected);
      });
    });

    describe('for a merged result pipeline', () => {
      it('renders a pipeline widget that reads "Merged result pipeline <ID> <status> for <SHA>"', () => {
        pipeline.details.name = 'Merged result pipeline';
        pipeline.merge_request_event_type = 'merged_result';

        createComponent(pipeline);

        const expected = `Merged result pipeline #${pipeline.id} ${pipeline.details.status.label} for ${pipeline.commit.short_id}`;
        const actual = trimText(wrapper.find('.js-pipeline-info-container').text());

        expect(actual).toBe(expected);
      });
    });
  });
});
