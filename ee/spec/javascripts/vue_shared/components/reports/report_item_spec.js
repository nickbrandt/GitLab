import Vue from 'vue';
import { componentNames } from 'ee/reports/components/issue_body';
import store from 'ee/vue_shared/security_reports/store';
import mountComponent, { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { codequalityParsedIssues } from 'ee_spec/vue_mr_widget/mock_data';
import {
  sastParsedIssues,
  dockerReportParsed,
  parsedDast,
} from 'ee_spec/vue_shared/security_reports/mock_data';
import { STATUS_FAILED, STATUS_SUCCESS } from '~/reports/constants';
import reportIssue from '~/reports/components/report_item.vue';

describe('Report issue', () => {
  let vm;
  let ReportIssue;

  beforeEach(() => {
    ReportIssue = Vue.extend(reportIssue);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('for codequality issue', () => {
    describe('resolved issue', () => {
      beforeEach(() => {
        vm = mountComponent(ReportIssue, {
          issue: codequalityParsedIssues[0],
          component: componentNames.CodequalityIssueBody,
          status: STATUS_SUCCESS,
        });
      });

      it('should render "Fixed" keyword', () => {
        expect(vm.$el.textContent).toContain('Fixed');
        expect(vm.$el.textContent.replace(/\s+/g, ' ').trim()).toEqual(
          'Fixed: Insecure Dependency in Gemfile.lock:12',
        );
      });
    });

    describe('unresolved issue', () => {
      beforeEach(() => {
        vm = mountComponent(ReportIssue, {
          issue: codequalityParsedIssues[0],
          component: componentNames.CodequalityIssueBody,
          status: STATUS_FAILED,
        });
      });

      it('should not render "Fixed" keyword', () => {
        expect(vm.$el.textContent).not.toContain('Fixed');
      });
    });
  });

  describe('with location', () => {
    it('should render location', () => {
      vm = mountComponent(ReportIssue, {
        issue: sastParsedIssues[0],
        component: componentNames.SastIssueBody,
        status: STATUS_FAILED,
      });

      expect(vm.$el.textContent).toContain('in');
      expect(vm.$el.querySelector('li a').getAttribute('href')).toEqual(
        sastParsedIssues[0].urlPath,
      );
    });
  });

  describe('without location', () => {
    it('should not render location', () => {
      vm = mountComponent(ReportIssue, {
        issue: {
          title: 'foo',
        },
        component: componentNames.SastIssueBody,
        status: STATUS_SUCCESS,
      });

      expect(vm.$el.textContent).not.toContain('in');
      expect(vm.$el.querySelector('a')).toEqual(null);
    });
  });

  describe('for container scanning issue', () => {
    beforeEach(() => {
      vm = mountComponent(ReportIssue, {
        issue: dockerReportParsed.unapproved[0],
        component: componentNames.SastContainerIssueBody,
        status: STATUS_FAILED,
      });
    });

    it('renders severity', () => {
      expect(vm.$el.textContent.trim()).toContain(dockerReportParsed.unapproved[0].severity);
    });

    it('renders CVE name', () => {
      expect(vm.$el.querySelector('button').textContent.trim()).toEqual(
        dockerReportParsed.unapproved[0].title,
      );
    });
  });

  describe('for dast issue', () => {
    beforeEach(() => {
      vm = mountComponentWithStore(ReportIssue, {
        store,
        props: {
          issue: parsedDast[0],
          component: componentNames.DastIssueBody,
          status: STATUS_FAILED,
        },
      });
    });

    it('renders severity (confidence) and title', () => {
      expect(vm.$el.textContent).toContain(parsedDast[0].title);
      expect(vm.$el.textContent).toContain(
        `${parsedDast[0].severity} (${parsedDast[0].confidence})`,
      );
    });
  });

  describe('showReportSectionStatusIcon', () => {
    it('does not render CI Status Icon when showReportSectionStatusIcon is false', () => {
      vm = mountComponentWithStore(ReportIssue, {
        store,
        props: {
          issue: parsedDast[0],
          component: componentNames.DastIssueBody,
          status: STATUS_SUCCESS,
          showReportSectionStatusIcon: false,
        },
      });

      expect(vm.$el.querySelectorAll('.report-block-list-icon')).toHaveLength(0);
    });

    it('shows status icon when unspecified', () => {
      vm = mountComponentWithStore(ReportIssue, {
        store,
        props: {
          issue: parsedDast[0],
          component: componentNames.DastIssueBody,
          status: STATUS_SUCCESS,
        },
      });

      expect(vm.$el.querySelectorAll('.report-block-list-icon')).toHaveLength(1);
    });
  });
});
