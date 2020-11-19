import Vue from 'vue';
import { mount } from '@vue/test-utils';
import { setHTMLFixture } from 'helpers/fixtures';
import PipelineStore from '~/pipelines/stores/pipeline_store';
import graphComponent from '~/pipelines/components/graph/graph_component.vue';
import StageColumnComponent from '~/pipelines/components/graph/stage_column_component.vue';
import linkedPipelinesColumn from '~/pipelines/components/graph/linked_pipelines_column.vue';
import graphJSON from './mock_data';
import linkedPipelineJSON from './linked_pipelines_mock_data';
import PipelinesMediator from '~/pipelines/pipeline_details_mediator';

describe('graph component', () => {
  let store;
  let mediator;
  let wrapper;

  const findExpandPipelineBtn = () => wrapper.find('[data-testid="expandPipelineButton"]');
  const findAllExpandPipelineBtns = () => wrapper.findAll('[data-testid="expandPipelineButton"]');
  const findStageColumns = () => wrapper.findAll(StageColumnComponent);
  const findStageColumnAt = i => findStageColumns().at(i);

  beforeEach(() => {
    mediator = new PipelinesMediator({ endpoint: '' });
    store = new PipelineStore();
    store.storePipeline(linkedPipelineJSON);

    setHTMLFixture('<div class="layout-page"></div>');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('while is loading', () => {
    it('should render a loading icon', () => {
      wrapper = mount(graphComponent, {
        propsData: {
          isLoading: true,
          pipeline: {},
          mediator,
        },
      });

      expect(wrapper.find('.gl-spinner').exists()).toBe(true);
    });
  });

  describe('with data', () => {
    beforeEach(() => {
      wrapper = mount(graphComponent, {
        propsData: {
          isLoading: false,
          pipeline: graphJSON,
          mediator,
        },
      });
    });

    it('renders the graph', () => {
      expect(wrapper.find('.js-pipeline-graph').exists()).toBe(true);
      expect(wrapper.find('.loading-icon').exists()).toBe(false);
      expect(wrapper.find('.stage-column-list').exists()).toBe(true);
    });

    it('renders columns in the graph', () => {
      expect(findStageColumns()).toHaveLength(graphJSON.details.stages.length);
    });
  });

  describe('when linked pipelines are not present', () => {
    beforeEach(() => {
      const pipeline = Object.assign(linkedPipelineJSON, { triggered: null, triggered_by: null });
      wrapper = mount(graphComponent, {
        propsData: {
          isLoading: false,
          pipeline,
          mediator,
        },
      });
    });

    describe('rendered output', () => {
      it('should include the first column with a no margin', () => {
        const firstColumn = wrapper.find('.stage-column');

        expect(firstColumn.classes('no-margin')).toBe(true);
      });

      it('should not render a linked pipelines column', () => {
        expect(wrapper.find('.linked-pipelines-column').exists()).toBe(false);
      });
    });

    describe('stageConnectorClass', () => {
      it('it returns no-margin when no triggerer and there is one job', () => {
        expect(findStageColumnAt(0).classes('no-margin')).toBe(true);
      });

      it('it returns left-margin when no triggerer and not the first stage', () => {
        expect(findStageColumnAt(1).classes('left-margin')).toBe(true);
      });
    });
  });

  describe('capitalizeStageName', () => {
    it('capitalizes and escapes stage name', () => {
      wrapper = mount(graphComponent, {
        propsData: {
          isLoading: false,
          pipeline: graphJSON,
          mediator,
        },
      });

      expect(findStageColumnAt(1).props('title')).toEqual(
        'Deploy &lt;img src=x onerror=alert(document.domain)&gt;',
      );
    });
  });
});
