import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import graphComponent from '~/pipelines/components/graph/graph_component.vue';
import pipelineJSON from 'spec/pipelines/graph/mock_data';
import linkedPipelineJSON from 'ee_spec/pipelines/graph/linked_pipelines_mock_data';

const graphJSON = Object.assign(pipelineJSON, {
  triggered: linkedPipelineJSON.triggered,
  triggered_by: linkedPipelineJSON.triggered_by,
});

describe('graph component', () => {
  const GraphComponent = Vue.extend(graphComponent);
  let component;

  afterEach(() => {
    component.$destroy();
  });

  describe('while is loading', () => {
    it('should render a loading icon', () => {
      component = mountComponent(GraphComponent, {
        isLoading: true,
        pipeline: {},
      });

      expect(component.$el.querySelector('.loading-icon')).toBeDefined();
    });
  });

  describe('when linked pipelines are present', () => {
    beforeEach(() => {
      component = mountComponent(GraphComponent, {
        isLoading: false,
        pipeline: graphJSON,
        triggeredByPipelines: [linkedPipelineJSON.triggered_by],
        triggeredPipelines: linkedPipelineJSON.triggered,
      });
    });

    describe('rendered output', () => {
      it('should include the pipelines graph', () => {
        expect(component.$el.classList.contains('js-pipeline-graph')).toEqual(true);
      });

      it('should not include the loading icon', () => {
        expect(component.$el.querySelector('.fa-spinner')).toBeNull();
      });

      it('should include the stage column list', () => {
        expect(component.$el.querySelector('.stage-column-list')).not.toBeNull();
      });

      it('should include the no-margin class on the first child', () => {
        const firstStageColumnElement = component.$el.querySelector(
          '.stage-column-list .stage-column',
        );

        expect(firstStageColumnElement.classList.contains('no-margin')).toEqual(true);
      });

      it('should include the has-only-one-job class on the first child', () => {
        const firstStageColumnElement = component.$el.querySelector(
          '.stage-column-list .stage-column',
        );

        expect(firstStageColumnElement.classList.contains('has-only-one-job')).toEqual(true);
      });

      it('should include the left-margin class on the second child', () => {
        const firstStageColumnElement = component.$el.querySelector(
          '.stage-column-list .stage-column:last-child',
        );

        expect(firstStageColumnElement.classList.contains('left-margin')).toEqual(true);
      });

      it('should include the has-linked-pipelines flag', () => {
        expect(component.$el.querySelector('.has-linked-pipelines')).not.toBeNull();
      });
    });

    describe('computeds and methods', () => {
      describe('capitalizeStageName', () => {
        it('it capitalizes the stage name', () => {
          expect(component.capitalizeStageName('mystage')).toBe('Mystage');
        });
      });

      describe('stageConnectorClass', () => {
        it('it returns left-margin when there is a triggerer', () => {
          expect(component.stageConnectorClass(0, { groups: ['job'] })).toBe('no-margin');
        });
      });
    });

    describe('linked pipelines components', () => {
      it('should render an upstream pipelines column', () => {
        expect(component.$el.querySelector('.linked-pipelines-column')).not.toBeNull();
        expect(component.$el.innerHTML).toContain('Upstream');
      });

      it('should render a downstream pipelines column', () => {
        expect(component.$el.querySelector('.linked-pipelines-column')).not.toBeNull();
        expect(component.$el.innerHTML).toContain('Downstream');
      });

      describe('triggered by', () => {
        it('should emit `onClickTriggeredBy` when triggered by linked pipeline is clicked', () => {
          spyOn(component, '$emit');
          component.$el.querySelector('#js-linked-pipeline-129').click();

          expect(component.$emit).toHaveBeenCalledWith(
            'onClickTriggeredBy',
            linkedPipelineJSON.triggered_by,
          );
        });

        describe('with expanded triggered by pipeline', () => {
          it('should render expanded upstream pipeline', () => {
            component = mountComponent(GraphComponent, {
              isLoading: false,
              pipeline: graphJSON,
              triggeredByPipelines: [
                Object.assign({}, linkedPipelineJSON.triggered_by, { isExpanded: true }),
              ],
              triggeredPipelines: linkedPipelineJSON.triggered,
              triggeredBy: linkedPipelineJSON.triggered_by,
            });

            expect(component.$el.querySelector('.upstream-pipeline')).not.toBeNull();
          });
        });
      });

      describe('triggered ', () => {
        it('should emit `onClickTriggered` when triggered linked pipeline is clicked', () => {
          spyOn(component, '$emit');
          component.$el.querySelector('#js-linked-pipeline-132').click();

          expect(component.$emit).toHaveBeenCalledWith(
            'onClickTriggered',
            linkedPipelineJSON.triggered[0],
          );
        });

        describe('with expanded triggered pipeline', () => {
          it('should render expanded downstream pipeline', () => {
            component = mountComponent(GraphComponent, {
              isLoading: false,
              pipeline: graphJSON,
              triggeredByPipelines: [linkedPipelineJSON.triggered_by],
              triggeredPipelines: [
                Object.assign({}, linkedPipelineJSON.triggered[0], { isExpanded: true }),
              ],
              triggered: linkedPipelineJSON.triggered[0],
            });

            expect(component.$el.querySelector('.downstream-pipeline')).not.toBeNull();
          });
        });
      });
    });
  });

  describe('when linked pipelines are not present', () => {
    beforeEach(() => {
      const pipeline = Object.assign(graphJSON, { triggered: null, triggered_by: null });
      component = mountComponent(GraphComponent, {
        isLoading: false,
        pipeline,
      });
    });

    describe('rendered output', () => {
      it('should include the first column with a no margin', () => {
        const firstColumn = component.$el.querySelector('.stage-column:first-child');

        expect(firstColumn.classList.contains('no-margin')).toEqual(true);
      });

      it('should not render a linked pipelines column', () => {
        expect(component.$el.querySelector('.linked-pipelines-column')).toBeNull();
      });
    });

    describe('stageConnectorClass', () => {
      it('it returns left-margin when no triggerer and there is one job', () => {
        expect(component.stageConnectorClass(0, { groups: ['job'] })).toBe('no-margin');
      });

      it('it returns left-margin when no triggerer and not the first stage', () => {
        expect(component.stageConnectorClass(99, { groups: ['job'] })).toBe('left-margin');
      });
    });
  });

  describe('capitalizeStageName', () => {
    it('capitalizes and escapes stage name', () => {
      component = mountComponent(GraphComponent, {
        isLoading: false,
        pipeline: graphJSON,
      });

      expect(
        component.$el.querySelector('.stage-column:nth-child(2) .stage-name').textContent.trim(),
      ).toEqual('Deploy &lt;img src=x onerror=alert(document.domain)&gt;');
    });
  });
});
