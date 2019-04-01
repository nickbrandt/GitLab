import Vue from 'vue';
import '~/commons/bootstrap';
import component from 'ee/vue_shared/security_reports/grouped_security_reports_app.vue';
import state from 'ee/vue_shared/security_reports/store/state';
import * as types from 'ee/vue_shared/security_reports/store/mutation_types';
import mountComponent from 'helpers/vue_mount_component_helper';
import { trimText } from 'helpers/vue_component_helper';
import {
  sastIssues,
  sastIssuesBase,
  dockerReport,
  dockerBaseReport,
  dast,
  dastBase,
} from './mock_data';

jest.mock(
  'ee/vue_shared/security_reports/store/actions',
  () => jest.genMockFromModule('ee/vue_shared/security_reports/store/actions').default,
);

describe('Grouped security reports app', () => {
  let vm;
  const Component = Vue.extend(component);

  const props = {
    headBlobPath: 'path',
    baseBlobPath: 'path',
    sastHeadPath: 'sast_head.json',
    sastBasePath: 'sast_base.json',
    dastHeadPath: 'dast_head.json',
    dastBasePath: 'dast_base.json',
    sastContainerHeadPath: 'sast_container_head.json',
    sastContainerBasePath: 'sast_container_base.json',
    dependencyScanningHeadPath: 'dss_head.json',
    dependencyScanningBasePath: 'dss_base.json',
    sastHelpPath: 'path',
    sastContainerHelpPath: 'path',
    dastHelpPath: 'path',
    dependencyScanningHelpPath: 'path',
    vulnerabilityFeedbackPath: 'vulnerability_feedback_path.json',
    vulnerabilityFeedbackHelpPath: 'path',
    pipelineId: 123,
    canCreateIssue: true,
    canCreateFeedback: true,
    pipelinePath: '/path/to/the/pipeline',
  };

  beforeEach(() => {
    vm = mountComponent(Component, props);
  });

  afterEach(() => {
    vm.$store.replaceState(state());
    vm.$destroy();
  });

  describe('while loading', () => {
    beforeEach(() => {
      Object.assign(vm.$store.state.sast, { isLoading: true });
      Object.assign(vm.$store.state.sastContainer, { isLoading: true });
      Object.assign(vm.$store.state.dast, { isLoading: true });
      Object.assign(vm.$store.state.dependencyScanning, { isLoading: true });

      return Vue.nextTick();
    });

    it('renders loading summary text + spinner', () => {
      expect(vm.$el.querySelector('.spinner')).not.toBeNull();
      expect(vm.$el.querySelector('.js-code-text').textContent.trim()).toEqual(
        'Security scanning is loading',
      );

      expect(vm.$el.querySelector('.js-collapse-btn').textContent.trim()).toEqual('Expand');

      expect(vm.$el.textContent).toContain('SAST is loading');
      expect(vm.$el.textContent).toContain('Dependency scanning is loading');
      expect(vm.$el.textContent).toContain('Container scanning is loading');
      expect(vm.$el.textContent).toContain('DAST is loading');
    });
  });

  describe('with error', () => {
    beforeEach(() => {
      Object.assign(vm.$store.state.sast, { isLoading: false, hasError: true });
      Object.assign(vm.$store.state.sastContainer, { isLoading: false, hasError: true });
      Object.assign(vm.$store.state.dast, { isLoading: false, hasError: true });
      Object.assign(vm.$store.state.dependencyScanning, { isLoading: false, hasError: true });

      return Vue.nextTick();
    });

    it('renders loading state', () => {
      expect(vm.$el.querySelector('.spinner')).toBeNull();
      expect(vm.$el.querySelector('.js-code-text').textContent.trim()).toEqual(
        'Security scanning failed loading any results',
      );

      expect(vm.$el.querySelector('.js-collapse-btn').textContent.trim()).toEqual('Expand');

      expect(trimText(vm.$el.textContent)).toContain('SAST: Loading resulted in an error');
      expect(trimText(vm.$el.textContent)).toContain(
        'Dependency scanning: Loading resulted in an error',
      );

      expect(vm.$el.textContent).toContain('Container scanning: Loading resulted in an error');
      expect(vm.$el.textContent).toContain('DAST: Loading resulted in an error');
    });
  });

  describe('with all reports', () => {
    beforeEach(() => {
      Object.assign(vm.$store.state.sast.paths, {
        head: props.sastHeadPath,
        base: props.sastBasePath,
      });
      Object.assign(vm.$store.state.sastContainer.paths, {
        head: props.sastContainerHeadPath,
        base: props.sastContainerBasePath,
      });
      Object.assign(vm.$store.state.dast.paths, {
        head: props.dastHeadPath,
        base: props.dastBasePath,
      });
      Object.assign(vm.$store.state.dependencyScanning.paths, {
        head: props.dependencyScanningHeadPath,
        base: props.dependencyScanningBasePath,
      });

      vm.$store.commit(types.RECEIVE_SAST_REPORTS, { head: sastIssues, base: sastIssuesBase });
      vm.$store.commit(types.RECEIVE_DAST_REPORTS, { head: dast, base: dastBase });
      vm.$store.commit(types.RECEIVE_SAST_CONTAINER_REPORTS, {
        head: dockerReport,
        base: dockerBaseReport,
      });
      vm.$store.commit(types.RECEIVE_DEPENDENCY_SCANNING_REPORTS, {
        head: sastIssues,
        base: sastIssuesBase,
      });

      return Vue.nextTick();
    });

    it('renders reports', () => {
      // It's not loading
      expect(vm.$el.querySelector('.spinner')).toBeNull();

      // Renders the summary text
      expect(vm.$el.querySelector('.js-code-text').textContent.trim()).toEqual(
        'Security scanning detected 6 new, and 3 fixed vulnerabilities',
      );

      // Renders the expand button
      expect(vm.$el.querySelector('.js-collapse-btn').textContent.trim()).toEqual('Expand');

      // Renders Sast result
      expect(trimText(vm.$el.textContent)).toContain(
        'SAST detected 2 new, and 1 fixed vulnerabilities',
      );

      // Renders DSS result
      expect(trimText(vm.$el.textContent)).toContain(
        'Dependency scanning detected 2 new, and 1 fixed vulnerabilities',
      );

      // Renders container scanning result
      expect(vm.$el.textContent).toContain(
        'Container scanning detected 1 new, and 1 fixed vulnerabilities',
      );

      // Renders DAST result
      expect(vm.$el.textContent).toContain('DAST detected 1 new vulnerability');
    });

    it('has the success icon for fixed vulnerabilities', () => {
      const icon = vm.$el.querySelector(
        '.js-sast-container~.js-plain-element .ic-status_success_borderless',
      );

      expect(icon).not.toBeNull();
    });
  });

  describe('the pipelinePath prop', () => {
    it('should calculate the security tab path', () => {
      expect(vm.securityTab).toEqual(`${props.pipelinePath}/security`);
    });
  });
});
