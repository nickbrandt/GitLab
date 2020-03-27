import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import * as urlUtility from '~/lib/utils/url_utility';

import createFlash from '~/flash';
import App from 'ee/vulnerabilities/components/app.vue';
import waitForPromises from 'helpers/wait_for_promises';
import ResolutionAlert from 'ee/vulnerabilities/components/resolution_alert.vue';
import VulnerabilityStateDropdown from 'ee/vulnerabilities/components/vulnerability_state_dropdown.vue';
import { VULNERABILITY_STATES } from 'ee/vulnerabilities/constants';

const vulnerabilityStateEntries = Object.entries(VULNERABILITY_STATES);
const mockAxios = new MockAdapter(axios);
jest.mock('~/flash');

describe('Vulnerability management app', () => {
  let wrapper;

  const defaultVulnerability = {
    id: 1,
    created_at: new Date().toISOString(),
    report_type: 'sast',
    state: 'detected',
  };

  const dataset = {
    createIssueUrl: 'create_issue_url',
    projectFingerprint: 'abc123',
    pipeline: {
      id: 2,
      created_at: new Date().toISOString(),
      url: 'pipeline_url',
    },
  };

  const findCreateIssueButton = () => wrapper.find({ ref: 'create-issue-btn' });
  const findBadge = () => wrapper.find({ ref: 'badge' });
  const findResolutionAlert = () => wrapper.find(ResolutionAlert);

  const createWrapper = (vulnerability = {}) => {
    wrapper = shallowMount(App, {
      propsData: {
        ...dataset,
        vulnerability: {
          ...defaultVulnerability,
          ...vulnerability,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    mockAxios.reset();
    createFlash.mockReset();
  });

  describe('state dropdown', () => {
    beforeEach(createWrapper);

    it('the vulnerability state dropdown is rendered', () => {
      expect(wrapper.find(VulnerabilityStateDropdown).exists()).toBe(true);
    });

    it('when the vulnerability state dropdown emits a change event, a POST API call is made', () => {
      const dropdown = wrapper.find(VulnerabilityStateDropdown);
      mockAxios.onPost().reply(201);

      dropdown.vm.$emit('change');

      return waitForPromises().then(() => {
        expect(mockAxios.history.post).toHaveLength(1); // Check that a POST request was made.
      });
    });

    it('when the vulnerability state changes but the API call fails, an error message is displayed', () => {
      const dropdown = wrapper.find(VulnerabilityStateDropdown);
      mockAxios.onPost().reply(400);

      dropdown.vm.$emit('change');

      return waitForPromises().then(() => {
        expect(mockAxios.history.post).toHaveLength(1);
        expect(createFlash).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('create issue button', () => {
    beforeEach(createWrapper);

    it('renders properly', () => {
      expect(findCreateIssueButton().exists()).toBe(true);
    });

    it('calls create issue endpoint on click and redirects to new issue', () => {
      const issueUrl = '/group/project/issues/123';
      const spy = jest.spyOn(urlUtility, 'redirectTo');
      mockAxios.onPost(dataset.createIssueUrl).reply(200, {
        issue_url: issueUrl,
      });
      findCreateIssueButton().vm.$emit('click');
      return waitForPromises().then(() => {
        expect(mockAxios.history.post).toHaveLength(1);
        const [postRequest] = mockAxios.history.post;
        expect(postRequest.url).toBe(dataset.createIssueUrl);
        expect(JSON.parse(postRequest.data)).toMatchObject({
          vulnerability_feedback: {
            feedback_type: 'issue',
            category: defaultVulnerability.report_type,
            project_fingerprint: dataset.projectFingerprint,
            vulnerability_data: {
              ...defaultVulnerability,
              category: defaultVulnerability.report_type,
              vulnerability_id: defaultVulnerability.id,
            },
          },
        });
        expect(spy).toHaveBeenCalledWith(issueUrl);
      });
    });

    it('shows an error message when issue creation fails', () => {
      mockAxios.onPost(dataset.createIssueUrl).reply(500);
      findCreateIssueButton().vm.$emit('click');
      return waitForPromises().then(() => {
        expect(mockAxios.history.post).toHaveLength(1);
        expect(createFlash).toHaveBeenCalledWith(
          'Something went wrong, could not create an issue.',
        );
      });
    });
  });

  describe('state badge', () => {
    test.each(vulnerabilityStateEntries)(
      'the vulnerability state badge has the correct style for the %s state',
      (state, stateObject) => {
        createWrapper({ state });

        expect(findBadge().classes()).toContain(`status-box-${stateObject.statusBoxStyle}`);
        expect(findBadge().text()).toBe(state);
      },
    );
  });

  describe('when the vulnerability is no-longer detected on the default branch', () => {
    const branchName = 'master';

    beforeEach(() => {
      createWrapper({
        resolved_on_default_branch: true,
        default_branch_name: branchName,
      });
    });

    it('should show the resolution alert component', () => {
      const alert = findResolutionAlert();

      expect(alert.exists()).toBe(true);
    });

    it('should pass down the default branch name', () => {
      const alert = findResolutionAlert();

      expect(alert.props().defaultBranchName).toEqual(branchName);
    });

    describe('when the vulnerability is already resolved', () => {
      beforeEach(() => {
        createWrapper({
          resolved_on_default_branch: true,
          state: 'resolved',
        });
      });

      it('should not show the resolution alert component', () => {
        const alert = findResolutionAlert();

        expect(alert.exists()).toBe(false);
      });
    });
  });
});
