import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import GroupedSecurityReportsApp from 'ee/vue_shared/security_reports/grouped_security_reports_app.vue';
import state from 'ee/vue_shared/security_reports/store/state';
import * as types from 'ee/vue_shared/security_reports/store/mutation_types';
import sastState from 'ee/vue_shared/security_reports/store/modules/sast/state';
import * as sastTypes from 'ee/vue_shared/security_reports/store/modules/sast/mutation_types';
import { mount } from '@vue/test-utils';
import { waitForMutation } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import axios from '~/lib/utils/axios_utils';
import { mrStates } from '~/mr_popover/constants';

import {
  sastDiffSuccessMock,
  dastDiffSuccessMock,
  containerScanningDiffSuccessMock,
  dependencyScanningDiffSuccessMock,
  mockFindings,
} from './mock_data';

const CONTAINER_SCANNING_DIFF_ENDPOINT = 'container_scanning.json';
const DEPENDENCY_SCANNING_DIFF_ENDPOINT = 'dependency_scanning.json';
const DAST_DIFF_ENDPOINT = 'dast.json';
const SAST_DIFF_ENDPOINT = 'sast.json';

describe('Grouped security reports app', () => {
  let wrapper;
  let mock;

  const props = {
    headBlobPath: 'path',
    baseBlobPath: 'path',
    sastHelpPath: 'path',
    containerScanningHelpPath: 'path',
    dastHelpPath: 'path',
    dependencyScanningHelpPath: 'path',
    vulnerabilityFeedbackPath: 'vulnerability_feedback_path.json',
    vulnerabilityFeedbackHelpPath: 'path',
    pipelineId: 123,
    canCreateIssue: true,
    canCreateMergeRequest: true,
    canDismissVulnerability: true,
  };

  const createWrapper = (propsData, provide = {}) => {
    wrapper = mount(GroupedSecurityReportsApp, {
      propsData,
      provide,
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet('vulnerability_feedback_path.json').reply(200, []);
  });

  afterEach(() => {
    wrapper.vm.$store.replaceState({
      ...state(),
      sast: sastState(),
    });
    wrapper.vm.$destroy();
    mock.restore();
  });

  describe('all reports', () => {
    const allReportProps = {
      ...props,
      enabledReports: {
        sast: true,
        dast: true,
        containerScanning: true,
        dependencyScanning: true,
      },
    };

    beforeEach(() => {
      gl.mrWidgetData = gl.mrWidgetData || {};
      gl.mrWidgetData.container_scanning_comparison_path = CONTAINER_SCANNING_DIFF_ENDPOINT;
      gl.mrWidgetData.dependency_scanning_comparison_path = DEPENDENCY_SCANNING_DIFF_ENDPOINT;
      gl.mrWidgetData.dast_comparison_path = DAST_DIFF_ENDPOINT;
      gl.mrWidgetData.sast_comparison_path = SAST_DIFF_ENDPOINT;
    });

    describe('with error', () => {
      beforeEach(() => {
        mock.onGet(CONTAINER_SCANNING_DIFF_ENDPOINT).reply(500);
        mock.onGet(DEPENDENCY_SCANNING_DIFF_ENDPOINT).reply(500);
        mock.onGet(DAST_DIFF_ENDPOINT).reply(500);
        mock.onGet(SAST_DIFF_ENDPOINT).reply(500);

        createWrapper(allReportProps);

        return Promise.all([
          waitForMutation(wrapper.vm.$store, `sast/${sastTypes.RECEIVE_DIFF_ERROR}`),
          waitForMutation(wrapper.vm.$store, types.RECEIVE_CONTAINER_SCANNING_DIFF_ERROR),
          waitForMutation(wrapper.vm.$store, types.RECEIVE_DAST_DIFF_ERROR),
          waitForMutation(wrapper.vm.$store, types.RECEIVE_DEPENDENCY_SCANNING_DIFF_ERROR),
        ]);
      });

      it('renders error state', () => {
        expect(wrapper.vm.$el.querySelector('.gl-spinner')).toBeNull();
        expect(wrapper.vm.$el.querySelector('.js-code-text').textContent.trim()).toEqual(
          'Security scanning failed loading any results',
        );

        expect(wrapper.vm.$el.querySelector('.js-collapse-btn').textContent.trim()).toEqual(
          'Expand',
        );

        expect(trimText(wrapper.vm.$el.textContent)).toContain(
          'SAST: Loading resulted in an error',
        );

        expect(trimText(wrapper.vm.$el.textContent)).toContain(
          'Dependency scanning: Loading resulted in an error',
        );

        expect(wrapper.vm.$el.textContent).toContain(
          'Container scanning: Loading resulted in an error',
        );

        expect(wrapper.vm.$el.textContent).toContain('DAST: Loading resulted in an error');
      });
    });

    describe('while loading', () => {
      beforeEach(() => {
        mock.onGet(CONTAINER_SCANNING_DIFF_ENDPOINT).reply(200, {});
        mock.onGet(DEPENDENCY_SCANNING_DIFF_ENDPOINT).reply(200, {});
        mock.onGet(DAST_DIFF_ENDPOINT).reply(200, {});
        mock.onGet(SAST_DIFF_ENDPOINT).reply(200, {});

        createWrapper(allReportProps);
      });

      it('renders loading summary text + spinner', () => {
        expect(wrapper.vm.$el.querySelector('.gl-spinner')).not.toBeNull();
        expect(wrapper.vm.$el.querySelector('.js-code-text').textContent.trim()).toEqual(
          'Security scanning is loading',
        );

        expect(wrapper.vm.$el.querySelector('.js-collapse-btn').textContent.trim()).toEqual(
          'Expand',
        );

        expect(wrapper.vm.$el.textContent).toContain('SAST is loading');
        expect(wrapper.vm.$el.textContent).toContain('Dependency scanning is loading');
        expect(wrapper.vm.$el.textContent).toContain('Container scanning is loading');
        expect(wrapper.vm.$el.textContent).toContain('DAST is loading');
      });
    });

    describe('with successful responses', () => {
      beforeEach(() => {
        mock.onGet(CONTAINER_SCANNING_DIFF_ENDPOINT).reply(200, containerScanningDiffSuccessMock);
        mock.onGet(DEPENDENCY_SCANNING_DIFF_ENDPOINT).reply(200, dependencyScanningDiffSuccessMock);
        mock.onGet(DAST_DIFF_ENDPOINT).reply(200, dastDiffSuccessMock);
        mock.onGet(SAST_DIFF_ENDPOINT).reply(200, sastDiffSuccessMock);

        createWrapper(allReportProps);

        return Promise.all([
          waitForMutation(wrapper.vm.$store, `sast/${sastTypes.RECEIVE_DIFF_SUCCESS}`),
          waitForMutation(wrapper.vm.$store, types.RECEIVE_DAST_DIFF_SUCCESS),
          waitForMutation(wrapper.vm.$store, types.RECEIVE_CONTAINER_SCANNING_DIFF_SUCCESS),
          waitForMutation(wrapper.vm.$store, types.RECEIVE_DEPENDENCY_SCANNING_DIFF_SUCCESS),
        ]);
      });

      it('renders reports', () => {
        // It's not loading
        expect(wrapper.vm.$el.querySelector('.gl-spinner')).toBeNull();

        // Renders the summary text
        expect(wrapper.vm.$el.querySelector('.js-code-text').textContent.trim()).toEqual(
          'Security scanning detected 6 new, and 6 fixed vulnerabilities',
        );

        // Renders the expand button
        expect(wrapper.vm.$el.querySelector('.js-collapse-btn').textContent.trim()).toEqual(
          'Expand',
        );

        // Renders Sast result
        expect(trimText(wrapper.vm.$el.textContent)).toContain(
          'SAST detected 1 new, and 2 fixed vulnerabilities',
        );

        // Renders DSS result
        expect(trimText(wrapper.vm.$el.textContent)).toContain(
          'Dependency scanning detected 2 new, and 1 fixed vulnerabilities',
        );

        // Renders container scanning result
        expect(wrapper.vm.$el.textContent).toContain(
          'Container scanning detected 2 new, and 1 fixed vulnerabilities',
        );

        // Renders DAST result
        expect(wrapper.vm.$el.textContent).toContain(
          'DAST detected 1 new, and 2 fixed vulnerabilities',
        );
      });

      it('opens modal with more information', () => {
        wrapper.vm.$el.querySelector('.break-link').click();

        return Vue.nextTick().then(() => {
          expect(wrapper.vm.$el.querySelector('.modal-title').textContent.trim()).toEqual(
            mockFindings[0].name,
          );

          expect(wrapper.vm.$el.querySelector('.modal-body').textContent).toContain(
            mockFindings[0].solution,
          );
        });
      });

      it('has the success icon for fixed vulnerabilities', () => {
        const icon = wrapper.vm.$el.querySelector(
          '.js-container-scanning~.js-plain-element .ic-status_success_borderless',
        );

        expect(icon).not.toBeNull();
      });
    });
  });

  describe('with the pipelinePath prop', () => {
    const pipelinePath = '/path/to/the/pipeline';

    beforeEach(() => {
      createWrapper({
        headBlobPath: 'path',
        canCreateIssue: false,
        canCreateMergeRequest: false,
        canDismissVulnerability: false,
        pipelinePath,
      });
    });

    it('should calculate the security tab path', () => {
      expect(wrapper.vm.securityTab).toEqual(`${pipelinePath}/security`);
    });
  });

  describe('container scanning reports', () => {
    beforeEach(() => {
      gl.mrWidgetData = gl.mrWidgetData || {};
      gl.mrWidgetData.container_scanning_comparison_path = CONTAINER_SCANNING_DIFF_ENDPOINT;

      mock.onGet(CONTAINER_SCANNING_DIFF_ENDPOINT).reply(200, containerScanningDiffSuccessMock);

      createWrapper({
        ...props,
        enabledReports: {
          containerScanning: true,
        },
      });

      return waitForMutation(wrapper.vm.$store, types.RECEIVE_CONTAINER_SCANNING_DIFF_SUCCESS);
    });

    it('should set setContainerScanningDiffEndpoint', () => {
      expect(wrapper.vm.containerScanning.paths.diffEndpoint).toEqual(
        CONTAINER_SCANNING_DIFF_ENDPOINT,
      );
    });

    it('should display the correct numbers of vulnerabilities', () => {
      expect(wrapper.vm.$el.textContent).toContain(
        'Container scanning detected 2 new, and 1 fixed vulnerabilities',
      );
    });
  });

  describe('dependency scanning reports', () => {
    beforeEach(() => {
      gl.mrWidgetData = gl.mrWidgetData || {};
      gl.mrWidgetData.dependency_scanning_comparison_path = DEPENDENCY_SCANNING_DIFF_ENDPOINT;

      mock.onGet(DEPENDENCY_SCANNING_DIFF_ENDPOINT).reply(200, dependencyScanningDiffSuccessMock);

      createWrapper({
        ...props,
        enabledReports: {
          dependencyScanning: true,
        },
      });

      return waitForMutation(wrapper.vm.$store, types.RECEIVE_DEPENDENCY_SCANNING_DIFF_SUCCESS);
    });

    it('should set setDependencyScanningDiffEndpoint', () => {
      expect(wrapper.vm.dependencyScanning.paths.diffEndpoint).toEqual(
        DEPENDENCY_SCANNING_DIFF_ENDPOINT,
      );
    });

    it('should display the correct numbers of vulnerabilities', () => {
      expect(wrapper.vm.$el.textContent).toContain(
        'Dependency scanning detected 2 new, and 1 fixed vulnerabilities',
      );
    });
  });

  describe('dast reports', () => {
    beforeEach(() => {
      gl.mrWidgetData = gl.mrWidgetData || {};
      gl.mrWidgetData.dast_comparison_path = DAST_DIFF_ENDPOINT;

      mock
        .onGet(DAST_DIFF_ENDPOINT)
        .reply(200, { ...dastDiffSuccessMock, base_report_out_of_date: true });

      createWrapper({
        ...props,
        enabledReports: {
          dast: true,
        },
      });

      return waitForMutation(wrapper.vm.$store, types.RECEIVE_DAST_DIFF_SUCCESS);
    });

    it('should set setDastDiffEndpoint', () => {
      expect(wrapper.vm.dast.paths.diffEndpoint).toEqual(DAST_DIFF_ENDPOINT);
    });

    it('should display the correct numbers of vulnerabilities', () => {
      expect(wrapper.vm.$el.textContent).toContain(
        'DAST detected 1 new, and 2 fixed vulnerabilities',
      );
    });
  });

  describe('sast reports', () => {
    beforeEach(() => {
      gl.mrWidgetData = gl.mrWidgetData || {};
      gl.mrWidgetData.sast_comparison_path = SAST_DIFF_ENDPOINT;

      mock.onGet(SAST_DIFF_ENDPOINT).reply(200, { ...sastDiffSuccessMock });

      createWrapper({
        ...props,
        enabledReports: {
          sast: true,
        },
      });

      return waitForMutation(wrapper.vm.$store, `sast/${sastTypes.RECEIVE_DIFF_SUCCESS}`);
    });

    it('should set setSastDiffEndpoint', () => {
      expect(wrapper.vm.sast.paths.diffEndpoint).toEqual(SAST_DIFF_ENDPOINT);
    });

    it('should display the correct numbers of vulnerabilities', () => {
      expect(wrapper.vm.$el.textContent).toContain(
        'SAST detected 1 new, and 2 fixed vulnerabilities',
      );
    });
  });

  describe('Out of date report', () => {
    const createComponent = (extraProp, done) => {
      gl.mrWidgetData = gl.mrWidgetData || {};
      gl.mrWidgetData.sast_comparison_path = SAST_DIFF_ENDPOINT;

      mock
        .onGet(SAST_DIFF_ENDPOINT)
        .reply(200, { ...sastDiffSuccessMock, base_report_out_of_date: true });

      createWrapper({
        ...props,
        ...extraProp,
        targetBranch: 'master',
        enabledReports: {
          sast: true,
        },
      });

      waitForMutation(wrapper.vm.$store, `sast/${sastTypes.RECEIVE_DIFF_SUCCESS}`)
        .then(done)
        .catch(done.fail);
    };

    describe('with active MR', () => {
      beforeEach(done => {
        createComponent({ mrState: mrStates.open }, done);
      });

      it('should display out of date message', () => {
        expect(wrapper.vm.$el.textContent).toContain(
          'Security report is out of date. Retry the pipeline for the target branch',
        );
      });
    });

    describe('with active MR and diverged commit', () => {
      beforeEach(done => {
        createComponent({ mrState: mrStates.open, divergedCommitsCount: 1 }, done);
      });

      it('should display out of date message', () => {
        expect(wrapper.vm.$el.textContent).toContain(
          'Security report is out of date. Please incorporate latest changes from master',
        );
      });
    });

    describe('with closed MR', () => {
      beforeEach(done => {
        createComponent({ mrState: mrStates.closed }, done);
      });

      it('should not display out of date message', () => {
        expect(wrapper.vm.$el.textContent).not.toContain('Security report is out of date.');
      });
    });

    describe('with merged MR', () => {
      beforeEach(done => {
        createComponent({ mrState: mrStates.merged }, done);
      });

      it('should not display out of date message', () => {
        expect(wrapper.vm.$el.textContent).not.toContain('Security report is out of date.');
      });
    });
  });
});
