import Vue from 'vue';
import '~/commons/bootstrap';

import component from 'ee/vue_shared/security_reports/split_security_reports_app.vue';
import createStore from 'ee/vue_shared/security_reports/store';
import state from 'ee/vue_shared/security_reports/store/state';
import * as types from 'ee/vue_shared/security_reports/store/mutation_types';
import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import { sastIssues, dast, dockerReport } from './mock_data';

jest.mock(
  'ee/vue_shared/security_reports/store/actions',
  () => jest.genMockFromModule('ee/vue_shared/security_reports/store/actions').default,
);

describe('Split security reports app', () => {
  const Component = Vue.extend(component);

  const props = {
    headBlobPath: 'path',
    sastHeadPath: 'sast_head.json',
    dependencyScanningHeadPath: 'dss_head.json',
    dastHeadPath: 'dast_head.json',
    sastContainerHeadPath: 'sast_container_head.json',
    sastHelpPath: 'path',
    dependencyScanningHelpPath: 'path',
    vulnerabilityFeedbackPath: 'vulnerability_feedback_path.json',
    vulnerabilityFeedbackHelpPath: 'path',
    dastHelpPath: 'path',
    sastContainerHelpPath: 'path',
    pipelineId: 123,
    canCreateIssue: true,
    canCreateFeedback: true,
  };

  let vm;

  beforeEach(() => {
    vm = mountComponentWithStore(Component, {
      store: createStore(),
      props,
    });
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

      expect(vm.$el.textContent).toContain('SAST is loading');
      expect(vm.$el.textContent).toContain('Dependency scanning is loading');
      expect(vm.$el.textContent).toContain('Container scanning is loading');
      expect(vm.$el.textContent).toContain('DAST is loading');
    });
  });

  describe('with all reports', () => {
    beforeEach(() => {
      Object.assign(vm.$store.state.sast.paths, {
        head: props.sastHeadPath,
      });
      Object.assign(vm.$store.state.sastContainer.paths, {
        head: props.sastContainerHeadPath,
      });
      Object.assign(vm.$store.state.dast.paths, {
        head: props.dastHeadPath,
      });
      Object.assign(vm.$store.state.dependencyScanning.paths, {
        head: props.dependencyScanningHeadPath,
      });

      vm.$store.commit(types.RECEIVE_SAST_REPORTS, { head: sastIssues });
      vm.$store.commit(types.RECEIVE_DAST_REPORTS, { head: dast });
      vm.$store.commit(types.RECEIVE_SAST_CONTAINER_REPORTS, {
        head: dockerReport,
      });
      vm.$store.commit(types.RECEIVE_DEPENDENCY_SCANNING_REPORTS, {
        head: sastIssues,
      });

      return Vue.nextTick();
    });

    it('renders reports', () => {
      expect(vm.$el.querySelector('.spinner')).toBeNull();

      expect(vm.$el.textContent).toContain('SAST detected 3 vulnerabilities');
      expect(vm.$el.textContent).toContain('Dependency scanning detected 3 vulnerabilities');

      // Renders container scanning result
      expect(vm.$el.textContent).toContain('Container scanning detected 2 vulnerabilities');

      // Renders DAST result
      expect(vm.$el.textContent).toContain('DAST detected 2 vulnerabilities');

      expect(vm.$el.textContent).not.toContain('for the source branch only');
    });

    it('renders all reports collapsed by default', () => {
      expect(vm.$el.querySelector('.spinner')).toBeNull();
      expect(vm.$el.querySelector('.js-collapse-btn').textContent.trim()).toEqual('Expand');

      const reports = vm.$el.querySelectorAll('.js-report-section-container');

      reports.forEach(report => {
        expect(report).toHaveCss({ display: 'none' });
      });
    });

    it('renders all reports expanded with the option always-open', () => {
      vm.alwaysOpen = true;

      return Vue.nextTick().then(() => {
        expect(vm.$el.querySelector('.spinner')).toBeNull();
        expect(vm.$el.querySelector('.js-collapse-btn')).toBeNull();

        const reports = vm.$el.querySelectorAll('.js-report-section-container');

        reports.forEach(report => {
          expect(report).not.toHaveCss({ display: 'none' });
        });
      });
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

    it('renders error state', () => {
      expect(vm.$el.querySelector('.spinner')).toBeNull();

      expect(vm.$el.textContent).toContain('SAST: Loading resulted in an error');
      expect(vm.$el.textContent).toContain('Dependency scanning: Loading resulted in an error');
      expect(vm.$el.textContent).toContain('Container scanning: Loading resulted in an error');
      expect(vm.$el.textContent).toContain('DAST: Loading resulted in an error');
    });
  });
});
