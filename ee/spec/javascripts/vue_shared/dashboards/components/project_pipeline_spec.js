import { mount, createLocalVue } from '@vue/test-utils';
import ProjectPipeline from 'ee/vue_shared/dashboards/components/project_pipeline.vue';
import { mockPipelineData } from '../mock_data';

const localVue = createLocalVue();

describe('project pipeline component', () => {
  const ProjectPipelineComponent = localVue.extend(ProjectPipeline);
  let wrapper;

  const mountComponent = (propsData = {}) =>
    mount(ProjectPipelineComponent, {
      propsData,
    });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('current pipeline only', () => {
    it('should render success badge', () => {
      wrapper = mountComponent({
        lastPipeline: mockPipelineData(),
        hasPipelineFailed: false,
      });

      expect(wrapper.contains('.js-ci-status-icon-success')).toBe(true);
    });

    it('should render failed badge', () => {
      wrapper = mountComponent({
        lastPipeline: mockPipelineData('failed'),
        hasPipelineFailed: true,
      });

      expect(wrapper.contains('.js-ci-status-icon-failed')).toBe(true);
    });

    it('should render running badge', () => {
      wrapper = mountComponent({
        lastPipeline: mockPipelineData('running'),
        hasPipelineFailed: false,
      });

      expect(wrapper.contains('.js-ci-status-icon-running')).toBe(true);
    });
  });

  describe('upstream pipeline', () => {
    it('should render upstream success badge', () => {
      const lastPipeline = mockPipelineData('success');
      lastPipeline.triggered_by = mockPipelineData('success');
      wrapper = mountComponent({
        lastPipeline,
        hasPipelineFailed: false,
      });

      expect(wrapper.contains('.js-upstream-pipeline-status.js-ci-status-icon-success')).toBe(true);
    });
  });

  describe('downstream pipeline', () => {
    it('should render downstream success badge', () => {
      const lastPipeline = mockPipelineData('success');
      lastPipeline.triggered = [mockPipelineData('success')];
      wrapper = mountComponent({
        lastPipeline,
        hasPipelineFailed: false,
      });

      expect(wrapper.contains('.js-downstream-pipeline-status.js-ci-status-icon-success')).toBe(
        true,
      );
    });

    it('should render downstream failed badge', () => {
      const lastPipeline = mockPipelineData('success');
      lastPipeline.triggered = [mockPipelineData('failed')];
      wrapper = mountComponent({
        lastPipeline,
        hasPipelineFailed: false,
      });

      expect(wrapper.contains('.js-downstream-pipeline-status.js-ci-status-icon-failed')).toBe(
        true,
      );
    });

    it('should render downstream running badge', () => {
      const lastPipeline = mockPipelineData('success');
      lastPipeline.triggered = [mockPipelineData('running')];
      wrapper = mountComponent({
        lastPipeline,
        hasPipelineFailed: false,
      });

      expect(wrapper.contains('.js-downstream-pipeline-status.js-ci-status-icon-running')).toBe(
        true,
      );
    });

    it('should render extra downstream icon', () => {
      const lastPipeline = mockPipelineData('success');
      // 5 is the max we can show, so put 6 in the array
      lastPipeline.triggered = Array.from(new Array(6), (val, index) =>
        mockPipelineData('running', index),
      );
      wrapper = mountComponent({
        lastPipeline,
        hasPipelineFailed: false,
      });

      expect(wrapper.contains('.js-downstream-extra-icon')).toBe(true);
    });
  });
});
