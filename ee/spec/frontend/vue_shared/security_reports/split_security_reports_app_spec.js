import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import { waitForMutation } from 'helpers/vue_test_utils_helper';
import component from 'ee/vue_shared/security_reports/split_security_reports_app.vue';
import createStore from 'ee/vue_shared/security_reports/store';
import state from 'ee/vue_shared/security_reports/store/state';
import * as types from 'ee/vue_shared/security_reports/store/mutation_types';
import * as sastTypes from 'ee/vue_shared/security_reports/store/modules/sast/mutation_types';
import { sastIssues, dast, dockerReport } from './mock_data';

const defaultProps = {
  canCreateIssue: true,
  canCreateMergeRequest: true,
  canDismissVulnerability: true,
  dastHeadPath: 'dast_head.json',
  dastHelpPath: 'dast_help.json',
  dependencyScanningHeadPath: 'dependency_scanning_head.json',
  dependencyScanningHelpPath: 'dependency_scanning_help.json',
  headBlobPath: 'head_blob.json',
  headReportEndpoint: 'head_report.json',
  pipelineId: 123,
  sastContainerHeadPath: 'sast_container_head.json',
  sastContainerHelpPath: 'sast_container_help.json',
  sastHeadPath: 'sast_head.json',
  sastHelpPath: 'sast_help.json',
  vulnerabilityFeedbackHelpPath: 'vulnerability_feedback_help.json',
  vulnerabilityFeedbackPath: 'vulnerability_feedback.json',
};

describe('Split security reports app', () => {
  const Component = Vue.extend(component);
  let vm;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    vm.$store.replaceState(state());
    vm.$destroy();
    mock.restore();
  });

  describe('while loading', () => {
    beforeEach(() => {
      mock.onGet(defaultProps.sastHeadPath).reply(200, sastIssues);
      mock.onGet(defaultProps.dependencyScanningHeadPath).reply(200, sastIssues);
      mock.onGet(defaultProps.dastHeadPath).reply(200, dast);
      mock.onGet(defaultProps.sastContainerHeadPath).reply(200, dockerReport);
      mock.onGet(defaultProps.vulnerabilityFeedbackPath).reply(200, []);

      vm = mountComponentWithStore(Component, {
        store: createStore(),
        props: defaultProps,
      });
    });

    it('renders loading summary text + spinner', () => {
      expect(vm.$el.querySelector('.gl-spinner')).not.toBeNull();
      expect(vm.$el.textContent).toContain('SAST is loading');
      expect(vm.$el.textContent).toContain('Dependency scanning is loading');
      expect(vm.$el.textContent).toContain('Container scanning is loading');
      expect(vm.$el.textContent).toContain('DAST is loading');
    });
  });

  describe('with all reports', () => {
    beforeEach(done => {
      mock.onGet(defaultProps.sastHeadPath).reply(200, sastIssues);
      mock.onGet(defaultProps.dependencyScanningHeadPath).reply(200, sastIssues);
      mock.onGet(defaultProps.dastHeadPath).reply(200, dast);
      mock.onGet(defaultProps.sastContainerHeadPath).reply(200, dockerReport);
      mock.onGet(defaultProps.vulnerabilityFeedbackPath).reply(200, []);

      vm = mountComponentWithStore(Component, {
        store: createStore(),
        props: defaultProps,
      });

      Promise.all([
        waitForMutation(vm.$store, `sast/${sastTypes.RECEIVE_REPORTS}`),
        waitForMutation(vm.$store, types.RECEIVE_SAST_CONTAINER_REPORTS),
        waitForMutation(vm.$store, types.RECEIVE_DAST_REPORTS),
        waitForMutation(vm.$store, types.RECEIVE_DEPENDENCY_SCANNING_REPORTS),
      ])
        .then(() => done())
        .catch();
    });

    it('renders reports', () => {
      expect(vm.$el.querySelector('.gl-spinner')).toBeNull();
      expect(vm.$el.textContent).toContain('SAST detected 3 vulnerabilities');
      expect(vm.$el.textContent).toContain('Dependency scanning detected 3 vulnerabilities');
      expect(vm.$el.textContent).toContain('Container scanning detected 2 vulnerabilities');
      expect(vm.$el.textContent).toContain('DAST detected 2 vulnerabilities');
      expect(vm.$el.textContent).not.toContain('for the source branch only');
    });

    it('renders all reports collapsed by default', () => {
      expect(vm.$el.querySelector('.gl-spinner')).toBeNull();
      expect(vm.$el.querySelector('.js-collapse-btn').textContent.trim()).toEqual('Expand');

      const reports = vm.$el.querySelectorAll('.js-report-section-container');

      reports.forEach(report => {
        expect(report).toHaveCss({
          display: 'none',
        });
      });
    });

    it('renders all reports expanded with the option always-open', done => {
      vm.alwaysOpen = true;
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.gl-spinner')).toBeNull();
        expect(vm.$el.querySelector('.js-collapse-btn')).toBeNull();

        const reports = vm.$el.querySelectorAll('.js-report-section-container');

        reports.forEach(report => {
          expect(report).not.toHaveCss({
            display: 'none',
          });
        });
        done();
      });
    });
  });

  describe('with error', () => {
    beforeEach(done => {
      mock.onGet(defaultProps.sastHeadPath).reply(500);
      mock.onGet(defaultProps.dependencyScanningHeadPath).reply(500);
      mock.onGet(defaultProps.dastHeadPath).reply(500);
      mock.onGet(defaultProps.sastContainerHeadPath).reply(500);
      mock.onGet(defaultProps.vulnerabilityFeedbackPath).reply(500, []);

      vm = mountComponentWithStore(Component, {
        store: createStore(),
        props: defaultProps,
      });

      Promise.all([
        waitForMutation(vm.$store, `sast/${sastTypes.RECEIVE_REPORTS_ERROR}`),
        waitForMutation(vm.$store, types.RECEIVE_SAST_CONTAINER_ERROR),
        waitForMutation(vm.$store, types.RECEIVE_DAST_ERROR),
        waitForMutation(vm.$store, types.RECEIVE_DEPENDENCY_SCANNING_ERROR),
      ])
        .then(() => done())
        .catch();
    });

    it('renders error state', () => {
      expect(vm.$el.querySelector('.gl-spinner')).toBeNull();
      expect(vm.$el.textContent).toContain('SAST: Loading resulted in an error');
      expect(vm.$el.textContent).toContain('Dependency scanning: Loading resulted in an error');
      expect(vm.$el.textContent).toContain('Container scanning: Loading resulted in an error');
      expect(vm.$el.textContent).toContain('DAST: Loading resulted in an error');
    });
  });

  describe('with the sastPipelineReportApi feature flag enabled', () => {
    beforeAll(() => {
      gon.features = { sastPipelineReportApi: true };
    });

    afterAll(() => {
      gon.features.sastPipelineReportApi = false;
    });

    describe('on success', () => {
      beforeEach(done => {
        mock
          .onGet(defaultProps.headReportEndpoint)
          .reply(200, sastIssues, { 'x-total': sastIssues.length });

        vm = mountComponentWithStore(Component, {
          store: createStore(),
          props: defaultProps,
        });

        waitForMutation(vm.$store, `sast/${sastTypes.RECEIVE_HEAD_REPORT_SUCCESS}`)
          .then(() => done())
          .catch();
      });

      it('should render the SAST report text', () => {
        expect(vm.$el.textContent).toContain('SAST detected 3 vulnerabilities');
      });
    });

    describe('on error', () => {
      beforeEach(done => {
        mock.onGet(defaultProps.headReportEndpoint).reply(500);

        vm = mountComponentWithStore(Component, {
          store: createStore(),
          props: defaultProps,
        });

        waitForMutation(vm.$store, `sast/${sastTypes.RECEIVE_HEAD_REPORT_ERROR}`)
          .then(() => done())
          .catch();
      });

      it('should render the error state', () => {
        expect(vm.$el.textContent).toContain('SAST: Loading resulted in an error');
      });
    });
  });
});
