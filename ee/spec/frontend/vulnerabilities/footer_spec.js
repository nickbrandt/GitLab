import { shallowMount } from '@vue/test-utils';
import VulnerabilityFooter from 'ee/vulnerabilities/components/footer.vue';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card.vue';
import IssueNote from 'ee/vue_shared/security_reports/components/issue_note.vue';
import { TEST_HOST } from 'helpers/test_constants';

describe('Vulnerability Footer', () => {
  let wrapper;

  const minimumProps = {
    solutionInfo: {
      hasDownload: false,
      hasMr: false,
      hasRemediation: false,
      isStandaloneVulnerability: true,
      remediation: null,
      solution: undefined,
      vulnerabilityFeedbackHelpPath:
        '/help/user/application_security/index#interacting-with-the-vulnerabilities',
    },
    project: {
      url: '/root/security-reports',
      value: 'Administrator / Security Reports',
    },
  };

  const solutionInfoProp = {
    hasDownload: true,
    hasMr: false,
    hasRemediation: true,
    isStandaloneVulnerability: true,
    remediation: {},
    solution: 'Upgrade to fixed version.\n',
    vulnerabilityFeedbackHelpPath:
      '/help/user/application_security/index#interacting-with-the-vulnerabilities',
  };

  const feedbackProps = {
    author: {},
    branch: null,
    category: 'container_scanning',
    created_at: '2020-03-18T00:10:49.527Z',
    feedback_type: 'issue',
    id: 36,
    issue_iid: 22,
    issue_url: `${TEST_HOST}/root/security-reports/-/issues/22`,
    project_fingerprint: 'f7319ea35fc016e754e9549dd89b338aea4c72cc',
    project_id: 19,
  };

  const createWrapper = (props = minimumProps) => {
    wrapper = shallowMount(VulnerabilityFooter, {
      propsData: props,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('solution card', () => {
    it('does show solution card when there is one', () => {
      createWrapper({ ...minimumProps, solutionInfo: solutionInfoProp });
      expect(wrapper.contains(SolutionCard)).toBe(true);
      expect(wrapper.find(SolutionCard).props()).toMatchObject(solutionInfoProp);
    });

    it('does not show solution card when there is not one', () => {
      createWrapper();
      expect(wrapper.contains(SolutionCard)).toBe(false);
    });
  });

  describe('issue history', () => {
    it('does show issue history when there is one', () => {
      createWrapper({ ...minimumProps, feedback: feedbackProps });
      expect(wrapper.contains(IssueNote)).toBe(true);
      expect(wrapper.find(IssueNote).props()).toMatchObject({
        feedback: feedbackProps,
        project: minimumProps.project,
      });
    });

    it('does not show issue history when there is not one', () => {
      createWrapper();
      expect(wrapper.contains(IssueNote)).toBe(false);
    });
  });
});
