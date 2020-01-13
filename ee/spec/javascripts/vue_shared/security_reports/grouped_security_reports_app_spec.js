import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import GroupedSecurityReportsApp from 'ee/vue_shared/security_reports/grouped_security_reports_app.vue';
import state from 'ee/vue_shared/security_reports/store/state';
import * as types from 'ee/vue_shared/security_reports/store/mutation_types';
import sastState from 'ee/vue_shared/security_reports/store/modules/sast/state';
import * as sastTypes from 'ee/vue_shared/security_reports/store/modules/sast/mutation_types';
import { mount } from '@vue/test-utils';
import { waitForMutation } from 'spec/helpers/vue_test_utils_helper';
import { trimText } from 'spec/helpers/text_helper';
import axios from '~/lib/utils/axios_utils';
import {
  sastIssues,
  sastIssuesBase,
  dockerReport,
  dockerBaseReport,
  dast,
  dastBase,
} from './mock_data';

describe('Grouped security reports app', () => {
  let wrapper;
  let mock;

  const createWrapper = (propsData, provide = {}) => {
    wrapper = mount(GroupedSecurityReportsApp, {
      propsData,
      provide,
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.vm.$store.replaceState({
      ...state(),
      sast: sastState(),
    });
    wrapper.vm.$destroy();
    mock.restore();
  });

  describe('with error', () => {
    beforeEach(done => {
      mock.onGet('sast_head.json').reply(500);
      mock.onGet('sast_base.json').reply(500);
      mock.onGet('dast_head.json').reply(500);
      mock.onGet('dast_base.json').reply(500);
      mock.onGet('sast_container_head.json').reply(500);
      mock.onGet('sast_container_base.json').reply(500);
      mock.onGet('dss_head.json').reply(500);
      mock.onGet('dss_base.json').reply(500);
      mock.onGet('vulnerability_feedback_path.json').reply(500, []);

      createWrapper({
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
        canCreateMergeRequest: true,
        canDismissVulnerability: true,
      });

      Promise.all([
        waitForMutation(wrapper.vm.$store, `sast/${sastTypes.RECEIVE_REPORTS_ERROR}`),
        waitForMutation(wrapper.vm.$store, types.RECEIVE_SAST_CONTAINER_ERROR),
        waitForMutation(wrapper.vm.$store, types.RECEIVE_DAST_ERROR),
        waitForMutation(wrapper.vm.$store, types.RECEIVE_DEPENDENCY_SCANNING_ERROR),
      ])
        .then(done)
        .catch(done.fail);
    });

    it('renders error state', () => {
      expect(wrapper.vm.$el.querySelector('.gl-spinner')).toBeNull();
      expect(wrapper.vm.$el.querySelector('.js-code-text').textContent.trim()).toEqual(
        'Security scanning failed loading any results',
      );

      expect(wrapper.vm.$el.querySelector('.js-collapse-btn').textContent.trim()).toEqual('Expand');

      expect(trimText(wrapper.vm.$el.textContent)).toContain('SAST: Loading resulted in an error');

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
      mock.onGet('sast_head.json').reply(200, sastIssues);
      mock.onGet('sast_base.json').reply(200, sastIssuesBase);
      mock.onGet('dast_head.json').reply(200, dast);
      mock.onGet('dast_base.json').reply(200, dastBase);
      mock.onGet('sast_container_head.json').reply(200, dockerReport);
      mock.onGet('sast_container_base.json').reply(200, dockerBaseReport);
      mock.onGet('dss_head.json').reply(200, sastIssues);
      mock.onGet('dss_base.json').reply(200, sastIssuesBase);
      mock.onGet('vulnerability_feedback_path.json').reply(200, []);

      createWrapper({
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
        canCreateMergeRequest: true,
        canDismissVulnerability: true,
      });
    });

    it('renders loading summary text + spinner', () => {
      expect(wrapper.vm.$el.querySelector('.gl-spinner')).not.toBeNull();
      expect(wrapper.vm.$el.querySelector('.js-code-text').textContent.trim()).toEqual(
        'Security scanning is loading',
      );

      expect(wrapper.vm.$el.querySelector('.js-collapse-btn').textContent.trim()).toEqual('Expand');

      expect(wrapper.vm.$el.textContent).toContain('SAST is loading');
      expect(wrapper.vm.$el.textContent).toContain('Dependency scanning is loading');
      expect(wrapper.vm.$el.textContent).toContain('Container scanning is loading');
      expect(wrapper.vm.$el.textContent).toContain('DAST is loading');
    });
  });

  describe('with all reports', () => {
    beforeEach(done => {
      mock.onGet('sast_head.json').reply(200, sastIssues);
      mock.onGet('sast_base.json').reply(200, sastIssuesBase);
      mock.onGet('dast_head.json').reply(200, dast);
      mock.onGet('dast_base.json').reply(200, dastBase);
      mock.onGet('sast_container_head.json').reply(200, dockerReport);
      mock.onGet('sast_container_base.json').reply(200, dockerBaseReport);
      mock.onGet('dss_head.json').reply(200, sastIssues);
      mock.onGet('dss_base.json').reply(200, sastIssuesBase);
      mock.onGet('vulnerability_feedback_path.json').reply(200, []);

      createWrapper({
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
        canCreateMergeRequest: true,
        canDismissVulnerability: true,
      });

      Promise.all([
        waitForMutation(wrapper.vm.$store, `sast/${sastTypes.RECEIVE_REPORTS}`),
        waitForMutation(wrapper.vm.$store, types.RECEIVE_DAST_REPORTS),
        waitForMutation(wrapper.vm.$store, types.RECEIVE_SAST_CONTAINER_REPORTS),
        waitForMutation(wrapper.vm.$store, types.RECEIVE_DEPENDENCY_SCANNING_REPORTS),
      ])
        .then(done)
        .catch(done.fail);
    });

    it('renders reports', () => {
      // It's not loading
      expect(wrapper.vm.$el.querySelector('.gl-spinner')).toBeNull();

      // Renders the summary text
      expect(wrapper.vm.$el.querySelector('.js-code-text').textContent.trim()).toEqual(
        'Security scanning detected 6 new, and 3 fixed vulnerabilities',
      );

      // Renders the expand button
      expect(wrapper.vm.$el.querySelector('.js-collapse-btn').textContent.trim()).toEqual('Expand');

      // Renders Sast result
      expect(trimText(wrapper.vm.$el.textContent)).toContain(
        'SAST detected 2 new, and 1 fixed vulnerabilities',
      );

      // Renders DSS result
      expect(trimText(wrapper.vm.$el.textContent)).toContain(
        'Dependency scanning detected 2 new, and 1 fixed vulnerabilities',
      );

      // Renders container scanning result
      expect(wrapper.vm.$el.textContent).toContain(
        'Container scanning detected 1 new, and 1 fixed vulnerabilities',
      );

      // Renders DAST result
      expect(wrapper.vm.$el.textContent).toContain('DAST detected 1 new vulnerability');
    });

    it('opens modal with more information', done => {
      setTimeout(() => {
        wrapper.vm.$el.querySelector('.break-link').click();

        Vue.nextTick(() => {
          expect(wrapper.vm.$el.querySelector('.modal-title').textContent.trim()).toEqual(
            sastIssues[0].message,
          );

          expect(wrapper.vm.$el.querySelector('.modal-body').textContent).toContain(
            sastIssues[0].solution,
          );

          done();
        });
      }, 0);
    });

    it('has the success icon for fixed vulnerabilities', done => {
      setTimeout(() => {
        const icon = wrapper.vm.$el.querySelector(
          '.js-sast-container~.js-plain-element .ic-status_success_borderless',
        );

        expect(icon).not.toBeNull();
        done();
      }, 0);
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

  describe('with the reports API enabled', () => {
    describe('container scanning reports', () => {
      const sastContainerEndpoint = 'sast_container.json';
      const props = {
        headBlobPath: 'path',
        baseBlobPath: 'path',
        sastHelpPath: 'path',
        sastContainerHelpPath: 'path',
        dastHelpPath: 'path',
        dependencyScanningHelpPath: 'path',
        vulnerabilityFeedbackPath: 'vulnerability_feedback_path.json',
        vulnerabilityFeedbackHelpPath: 'path',
        pipelineId: 123,
        canCreateIssue: true,
        canCreateMergeRequest: true,
        canDismissVulnerability: true,
      };
      const provide = {
        glFeatures: {
          containerScanningMergeRequestReportApi: true,
        },
      };

      beforeEach(() => {
        gl.mrWidgetData = gl.mrWidgetData || {};
        gl.mrWidgetData.container_scanning_comparison_path = sastContainerEndpoint;

        mock.onGet(sastContainerEndpoint).reply(200, {
          added: [dockerReport.vulnerabilities[0], dockerReport.vulnerabilities[1]],
          fixed: [dockerReport.vulnerabilities[2]],
        });

        mock.onGet('vulnerability_feedback_path.json').reply(200, []);
      });

      describe('with reports disabled', () => {
        beforeEach(() => {
          createWrapper(
            {
              ...props,
              enabledReports: {
                containerScanning: false,
              },
            },
            provide,
          );
        });

        it('should not render the widget', () => {
          expect(wrapper.vm.$el.querySelector('.js-sast-container')).toBeNull();
        });
      });

      describe('with reports enabled', () => {
        beforeEach(done => {
          createWrapper(
            {
              ...props,
              enabledReports: {
                containerScanning: true,
              },
            },
            provide,
          );

          waitForMutation(wrapper.vm.$store, types.RECEIVE_SAST_CONTAINER_DIFF_SUCCESS)
            .then(done)
            .catch(done.fail);
        });

        it('should set setSastContainerDiffEndpoint', () => {
          expect(wrapper.vm.sastContainer.paths.diffEndpoint).toEqual(sastContainerEndpoint);
        });

        it('should display the correct numbers of vulnerabilities', () => {
          expect(wrapper.vm.$el.textContent).toContain(
            'Container scanning detected 2 new, and 1 fixed vulnerabilities',
          );
        });
      });
    });

    describe('dependency scanning reports', () => {
      const dependencyScanningEndpoint = 'dependency_scanning.json';
      const props = {
        headBlobPath: 'path',
        baseBlobPath: 'path',
        sastHelpPath: 'path',
        sastContainerHelpPath: 'path',
        dastHelpPath: 'path',
        dependencyScanningHelpPath: 'path',
        vulnerabilityFeedbackPath: 'vulnerability_feedback_path.json',
        vulnerabilityFeedbackHelpPath: 'path',
        pipelineId: 123,
        canCreateIssue: true,
        canCreateMergeRequest: true,
        canDismissVulnerability: true,
      };
      const provide = {
        glFeatures: {
          dependencyScanningMergeRequestReportApi: true,
        },
      };

      beforeEach(() => {
        gl.mrWidgetData = gl.mrWidgetData || {};
        gl.mrWidgetData.dependency_scanning_comparison_path = dependencyScanningEndpoint;

        mock.onGet(dependencyScanningEndpoint).reply(200, {
          added: [dockerReport.vulnerabilities[0], dockerReport.vulnerabilities[1]],
          fixed: [dockerReport.vulnerabilities[2]],
        });

        mock.onGet('vulnerability_feedback_path.json').reply(200, []);
      });

      describe('with reports disabled', () => {
        beforeEach(() => {
          createWrapper(
            {
              ...props,
              enabledReports: {
                dependencyScanning: false,
              },
            },
            provide,
          );
        });

        it('should not render the widget', () => {
          expect(wrapper.vm.$el.querySelector('.js-dependency-scanning-widget')).toBeNull();
        });
      });

      describe('with reports enabled', () => {
        beforeEach(done => {
          createWrapper(
            {
              ...props,
              enabledReports: {
                dependencyScanning: true,
              },
            },
            provide,
          );

          waitForMutation(wrapper.vm.$store, types.RECEIVE_DEPENDENCY_SCANNING_DIFF_SUCCESS)
            .then(done)
            .catch(done.fail);
        });

        it('should set setDependencyScanningDiffEndpoint', () => {
          expect(wrapper.vm.dependencyScanning.paths.diffEndpoint).toEqual(
            dependencyScanningEndpoint,
          );
        });

        it('should display the correct numbers of vulnerabilities', () => {
          expect(wrapper.vm.$el.textContent).toContain(
            'Dependency scanning detected 2 new, and 1 fixed vulnerabilities',
          );
        });
      });
    });

    describe('dast reports', () => {
      const dastEndpoint = 'dast.json';
      const props = {
        headBlobPath: 'path',
        baseBlobPath: 'path',
        sastHelpPath: 'path',
        sastContainerHelpPath: 'path',
        dastHelpPath: 'path',
        dependencyScanningHelpPath: 'path',
        vulnerabilityFeedbackPath: 'vulnerability_feedback_path.json',
        vulnerabilityFeedbackHelpPath: 'path',
        pipelineId: 123,
        canCreateIssue: true,
        canCreateMergeRequest: true,
        canDismissVulnerability: true,
      };
      const provide = {
        glFeatures: {
          dastMergeRequestReportApi: true,
        },
      };

      beforeEach(() => {
        gl.mrWidgetData = gl.mrWidgetData || {};
        gl.mrWidgetData.dast_comparison_path = dastEndpoint;

        mock.onGet(dastEndpoint).reply(200, {
          added: [dockerReport.vulnerabilities[0]],
          fixed: [dockerReport.vulnerabilities[1], dockerReport.vulnerabilities[2]],
          base_report_out_of_date: true,
        });

        mock.onGet('vulnerability_feedback_path.json').reply(200, []);
      });

      describe('with reports disabled', () => {
        beforeEach(() => {
          createWrapper(
            {
              ...props,
              enabledReports: {
                dast: false,
              },
            },
            provide,
          );
        });

        it('should not render the widget', () => {
          expect(wrapper.vm.$el.querySelector('.js-dast-widget')).toBeNull();
        });
      });

      describe('with reports enabled', () => {
        beforeEach(done => {
          createWrapper(
            {
              ...props,
              enabledReports: {
                dast: true,
              },
            },
            provide,
          );

          waitForMutation(wrapper.vm.$store, types.RECEIVE_DAST_DIFF_SUCCESS)
            .then(done)
            .catch(done.fail);
        });

        it('should set setDastDiffEndpoint', () => {
          expect(wrapper.vm.dast.paths.diffEndpoint).toEqual(dastEndpoint);
        });

        it('should display the correct numbers of vulnerabilities', () => {
          expect(wrapper.vm.$el.textContent).toContain(
            'DAST detected 1 new, and 2 fixed vulnerabilities',
          );
        });

        it('should display out of date message', () => {
          expect(wrapper.vm.$el.textContent).toContain(
            'Security report is out of date. Retry the pipeline for the target branch',
          );
        });
      });
    });

    describe('sast reports', () => {
      const sastEndpoint = 'sast.json';
      const props = {
        headBlobPath: 'path',
        baseBlobPath: 'path',
        sastHelpPath: 'path',
        sastContainerHelpPath: 'path',
        dastHelpPath: 'path',
        dependencyScanningHelpPath: 'path',
        vulnerabilityFeedbackPath: 'vulnerability_feedback_path.json',
        vulnerabilityFeedbackHelpPath: 'path',
        pipelineId: 123,
        canCreateIssue: true,
        canCreateMergeRequest: true,
        canDismissVulnerability: true,
        targetBranch: 'master',
      };
      const provide = {
        glFeatures: {
          sastMergeRequestReportApi: true,
        },
      };

      beforeEach(() => {
        gl.mrWidgetData = gl.mrWidgetData || {};
        gl.mrWidgetData.sast_comparison_path = sastEndpoint;
        gl.mrWidgetData.diverged_commits_count = 100;

        mock.onGet(sastEndpoint).reply(200, {
          added: [dockerReport.vulnerabilities[0]],
          fixed: [dockerReport.vulnerabilities[1], dockerReport.vulnerabilities[2]],
          existing: [dockerReport.vulnerabilities[2]],
          base_report_out_of_date: true,
        });

        mock.onGet('vulnerability_feedback_path.json').reply(200, []);
      });

      describe('with reports disabled', () => {
        beforeEach(() => {
          createWrapper(
            {
              ...props,
              enabledReports: {
                sast: false,
              },
            },
            provide,
          );
        });

        it('should not render the widget', () => {
          expect(wrapper.vm.$el.querySelector('.js-sast-widget')).toBeNull();
        });
      });

      describe('with reports enabled', () => {
        beforeEach(done => {
          createWrapper(
            {
              ...props,
              enabledReports: {
                sast: true,
              },
            },
            provide,
          );

          waitForMutation(wrapper.vm.$store, `sast/${sastTypes.RECEIVE_DIFF_SUCCESS}`)
            .then(done)
            .catch(done.fail);
        });

        it('should set setSastDiffEndpoint', () => {
          expect(wrapper.vm.sast.paths.diffEndpoint).toEqual(sastEndpoint);
        });

        it('should display the correct numbers of vulnerabilities', () => {
          expect(wrapper.vm.$el.textContent).toContain(
            'SAST detected 1 new, and 2 fixed vulnerabilities',
          );
        });

        it('should display out of date message for Outdated MR ', () => {
          expect(wrapper.vm.$el.textContent).toContain(
            'Security report is out of date. Please incorporate latest changes from master',
          );
        });
      });
    });
  });
});
