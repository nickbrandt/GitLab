import Vue from 'vue';
import '~/commons/bootstrap';
import { TEST_HOST } from 'helpers/test_constants';

import component from 'ee/vue_shared/security_reports/card_security_reports_app.vue';
import createStore from 'ee/vue_shared/security_reports/store';
import state from 'ee/vue_shared/security_reports/store/state';
import * as types from 'ee/vue_shared/security_reports/store/mutation_types';
import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import { trimText } from 'helpers/vue_component_helper';

import { sastIssues, dast, dockerReport } from './mock_data';

jest.mock(
  'ee/vue_shared/security_reports/store/actions',
  () => jest.genMockFromModule('ee/vue_shared/security_reports/store/actions').default,
);

const createTestProps = (createdDate = new Date()) => ({
  hasPipelineData: true,
  emptyStateIllustrationPath: `${TEST_HOST}/img`,
  securityDashboardHelpPath: `${TEST_HOST}/help_dashboard`,
  commit: {
    id: '1234adf',
    path: `${TEST_HOST}/commit`,
  },
  branch: {
    id: 'master',
    path: `${TEST_HOST}/branch`,
  },
  pipeline: {
    id: '55',
    created: createdDate.toISOString(),
    path: `${TEST_HOST}/pipeline`,
  },
  triggeredBy: {
    path: `${TEST_HOST}/user`,
    avatarPath: `${TEST_HOST}/img`,
    name: 'TestUser',
  },
  headBlobPath: 'path',
  baseBlobPath: 'path',
  sastHeadPath: `${TEST_HOST}/sast_head`,
  dependencyScanningHeadPath: `${TEST_HOST}/dss_head`,
  dastHeadPath: `${TEST_HOST}/dast_head`,
  sastContainerHeadPath: `${TEST_HOST}/sast_container_head`,
  sastHelpPath: 'path',
  dependencyScanningHelpPath: 'path',
  vulnerabilityFeedbackPath: `${TEST_HOST}/vulnerability_feedback_path`,
  vulnerabilityFeedbackHelpPath: 'path',
  dastHelpPath: 'path',
  sastContainerHelpPath: 'path',
  pipelineId: 123,
  canCreateFeedback: true,
  canCreateIssue: true,
});

describe('Card security reports app', () => {
  const Component = Vue.extend(component);

  let vm;
  const createdDate = new Date();
  createdDate.setDate(createdDate.getDate() - 7);
  const props = createTestProps(createdDate);

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

  describe('computed properties', () => {
    describe('headline', () => {
      it('renders `Pipeline <link> triggered`', () => {
        expect(vm.headline).toBe(`Pipeline <a href="${TEST_HOST}/pipeline">#55</a> triggered`);
      });
    });
  });

  describe('Headline renders', () => {
    it('pipeline metadata information', () => {
      const element = vm.$el.querySelector('.card-header .js-security-dashboard-left');

      expect(trimText(element.textContent)).toBe('Pipeline #55 triggered 1 week ago by TestUser');

      const pipelineLink = element.querySelector(`a[href="${TEST_HOST}/pipeline"]`);

      expect(pipelineLink).not.toBeNull();
      expect(pipelineLink.textContent).toBe('#55');

      const userAvatarLink = element.querySelector('a.user-avatar-link');

      expect(userAvatarLink).not.toBeNull();
      expect(userAvatarLink.getAttribute('href')).toBe(`${TEST_HOST}/user`);
      expect(userAvatarLink.querySelector('img').getAttribute('src')).toBe(
        `${TEST_HOST}/img?width=24`,
      );

      expect(userAvatarLink.textContent.trim()).toBe('TestUser');
    });

    it('branch and commit information', () => {
      const branchIcon = vm.$el.querySelector(
        '.card-header .js-security-dashboard-right .ic-branch',
      );

      expect(branchIcon).not.toBeNull();

      const branchLink = branchIcon.nextElementSibling;

      expect(branchLink).not.toBeNull();
      expect(branchLink.textContent).toBe('master');
      expect(branchLink.getAttribute('href')).toBe(`${TEST_HOST}/branch`);

      const middot = branchLink.nextElementSibling;

      expect(middot).not.toBeNull();
      expect(middot.textContent).toBe('·');

      const commitIcon = middot.nextElementSibling;

      expect(commitIcon).not.toBeNull();
      expect(commitIcon.classList).toContain('ic-commit');

      const commitLink = commitIcon.nextElementSibling;

      expect(commitLink).not.toBeNull();
      expect(commitLink.textContent).toContain('1234adf');
      expect(commitLink.getAttribute('href')).toBe(`${TEST_HOST}/commit`);
    });
  });

  describe('Empty State renders correctly', () => {
    beforeEach(() => {
      vm.hasPipelineData = false;
      return Vue.nextTick();
    });

    it('image illustration is set to defined path', () => {
      const imgEl = vm.$el.querySelector('img');

      expect(imgEl.getAttribute('src')).toBe(`${TEST_HOST}/img`);
    });

    it('headline text is to `Monitor vulnerabilities in your code`', () => {
      const headingEl = vm.$el.querySelector('h4');

      expect(headingEl.textContent.trim()).toBe('Monitor vulnerabilities in your code');
    });

    it('paragraph text is to `The security dashboard...`', () => {
      const paragraphEl = vm.$el.querySelector('p');

      expect(trimText(paragraphEl.textContent)).toBe(
        'The security dashboard displays the latest security report. Use it to find and fix vulnerabilities.',
      );
    });

    it('learn more link has correct path and text', () => {
      const linkEl = vm.$el.querySelector('a');

      expect(linkEl.textContent.trim()).toBe('Learn more');
      expect(linkEl.getAttribute('href')).toBe(`${TEST_HOST}/help_dashboard`);
    });
  });

  describe('Report renders correctly', () => {
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

      it('renders all reports expanded and with no way to collapse', () => {
        expect(vm.$el.querySelector('.spinner')).toBeNull();
        expect(vm.$el.querySelector('.js-collapse-btn')).toBeNull();

        const reports = vm.$el.querySelectorAll('.js-report-section-container');

        reports.forEach(report => {
          expect(report).not.toHaveCss({ display: 'none' });
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
});
