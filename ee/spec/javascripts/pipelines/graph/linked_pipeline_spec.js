import Vue from 'vue';
import LinkedPipelineComponent from 'ee/pipelines/components/graph/linked_pipeline.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import mockData from './linked_pipelines_mock_data';

const mockPipeline = mockData.triggered[0];

describe('Linked pipeline', () => {
  const Component = Vue.extend(LinkedPipelineComponent);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('while is loading', () => {
    const props = {
      pipelineId: mockPipeline.id,
      pipelinePath: mockPipeline.path,
      pipelineStatus: mockPipeline.details.status,
      projectName: mockPipeline.project.name,
      isLoading: true,
    };

    beforeEach(() => {
      vm = mountComponent(Component, props);
    });

    it('renders loading icon', () => {
      expect(vm.$el.querySelector('.js-linked-pipeline-loading')).not.toBeNull();
    });
  });

  describe('when it is not loading', () => {
    const props = {
      pipelineId: mockPipeline.id,
      pipelinePath: mockPipeline.path,
      pipelineStatus: mockPipeline.details.status,
      projectName: mockPipeline.project.name,
      isLoading: false,
    };

    beforeEach(() => {
      vm = mountComponent(Component, props);
    });

    it('should render a list item as the containing element', () => {
      expect(vm.$el.tagName).toBe('LI');
    });

    it('should render a button', () => {
      const linkElement = vm.$el.querySelector('.js-linked-pipeline-content');

      expect(linkElement).not.toBeNull();
    });

    it('should render the project name', () => {
      expect(vm.$el.innerText).toContain(props.projectName);
    });

    it('should render an svg within the status container', () => {
      const pipelineStatusElement = vm.$el.querySelector('.js-linked-pipeline-status');

      expect(pipelineStatusElement.querySelector('svg')).not.toBeNull();
    });

    it('should render the pipeline status icon svg', () => {
      expect(vm.$el.querySelector('.js-ci-status-icon-running')).not.toBeNull();
      expect(vm.$el.querySelector('.js-ci-status-icon-running').innerHTML).toContain('<svg');
    });

    it('should have a ci-status child component', () => {
      expect(vm.$el.querySelector('.js-linked-pipeline-status')).not.toBeNull();
    });

    it('should render the pipeline id', () => {
      expect(vm.$el.innerText).toContain(`#${props.pipelineId}`);
    });

    it('should correctly compute the tooltip text', () => {
      expect(vm.tooltipText).toContain(mockPipeline.project.name);
      expect(vm.tooltipText).toContain(mockPipeline.details.status.label);
    });

    it('should render the tooltip text as the title attribute', () => {
      const tooltipRef = vm.$el.querySelector('.js-linked-pipeline-content');
      const titleAttr = tooltipRef.getAttribute('data-original-title');

      expect(titleAttr).toContain(mockPipeline.project.name);
      expect(titleAttr).toContain(mockPipeline.details.status.label);
    });
  });

  describe('on click', () => {
    const props = {
      pipelineId: mockPipeline.id,
      pipelinePath: mockPipeline.path,
      pipelineStatus: mockPipeline.details.status,
      projectName: mockPipeline.project.name,
      isLoading: false,
    };

    beforeEach(() => {
      vm = mountComponent(Component, props);
    });

    it('emits `pipelineClicked` event', () => {
      spyOn(vm, '$emit');
      vm.$el.querySelector('button').click();

      expect(vm.$emit).toHaveBeenCalledWith('pipelineClicked');
    });

    it('should emit `bv::hide::tooltip` to close the tooltip', () => {
      spyOn(vm.$root, '$emit');
      vm.$el.querySelector('button').click();

      expect(vm.$root.$emit).toHaveBeenCalledWith(
        'bv::hide::tooltip',
        `js-linked-pipeline-${props.pipelineId}`,
      );
    });
  });
});
