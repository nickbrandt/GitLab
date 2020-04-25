import { shallowMount } from '@vue/test-utils';
import VulnerabilityFooter from 'ee/vulnerabilities/components/footer.vue';
import HistoryEntry from 'ee/vulnerabilities/components/history_entry.vue';
import VulnerabilitiesEventBus from 'ee/vulnerabilities/components/vulnerabilities_event_bus';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card.vue';
import IssueNote from 'ee/vue_shared/security_reports/components/issue_note.vue';
import { TEST_HOST } from 'helpers/test_constants';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';

const mockAxios = new MockAdapter(axios);
jest.mock('~/flash');

describe('Vulnerability Footer', () => {
  let wrapper;

  const minimumProps = {
    discussionsUrl: `/discussions`,
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
    wrapper = null;
    mockAxios.reset();
  });

  describe('vulnerabilities event bus listener', () => {
    it('calls the discussion url on vulnerabilities event bus emit of VULNERABILITY_STATE_CHANGE', () => {
      createWrapper();
      jest.spyOn(axios, 'get');
      VulnerabilitiesEventBus.$emit('VULNERABILITY_STATE_CHANGE');
      expect(axios.get).toHaveBeenCalledTimes(1);
    });
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

  describe('state history', () => {
    const discussionUrl = '/discussions';

    const historyList = () => wrapper.find({ ref: 'historyList' });
    const historyEntries = () => wrapper.findAll(HistoryEntry);

    it('does not render the history list if there are no history items', () => {
      mockAxios.onGet(discussionUrl).replyOnce(200, []);
      createWrapper();
      expect(historyList().exists()).toBe(false);
    });

    it('renders the history list if there are history items', () => {
      // The shape of this object doesn't matter for this test, we just need to verify that it's passed to the history
      // entry.
      const historyItems = [{ id: 1, note: 'some note' }, { id: 2, note: 'another note' }];
      mockAxios.onGet(discussionUrl).replyOnce(200, historyItems);
      createWrapper();

      return axios.waitForAll().then(() => {
        expect(historyList().exists()).toBe(true);
        expect(historyEntries()).toHaveLength(2);
        const entry1 = historyEntries().at(0);
        const entry2 = historyEntries().at(1);
        expect(entry1.props('discussion')).toEqual(historyItems[0]);
        expect(entry2.props('discussion')).toEqual(historyItems[1]);
      });
    });

    it('shows an error the history list could not be retrieved', () => {
      mockAxios.onGet(discussionUrl).replyOnce(500);
      createWrapper();

      return axios.waitForAll().then(() => {
        expect(createFlash).toHaveBeenCalledTimes(1);
      });
    });
  });
});
