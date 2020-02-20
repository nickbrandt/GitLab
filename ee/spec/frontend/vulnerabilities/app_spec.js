import { shallowMount } from '@vue/test-utils';
import axios from '~/lib/utils/axios_utils';
import { redirectTo } from '~/lib/utils/url_utility';

import createFlash from '~/flash';
import MockAdapter from 'axios-mock-adapter';
import App from 'ee/vulnerabilities/components/app.vue';
import waitForPromises from 'helpers/wait_for_promises';
import VulnerabilityStateDropdown from 'ee/vulnerabilities/components/vulnerability_state_dropdown.vue';

const mockAxios = new MockAdapter(axios);
jest.mock('~/flash');
jest.mock('~/lib/utils/url_utility');

describe('Vulnerability management app', () => {
  let wrapper;

  const vulnerability = {
    id: 1,
    state: 'doesnt matter',
    report_type: 'sast',
  };
  const finding = {
    project_fingerprint: 'abc123',
    report_type: 'sast',
  };
  const createIssueUrl = 'create_issue_path';

  const findCreateIssueButton = () => wrapper.find({ ref: 'create-issue-btn' });

  beforeEach(() => {
    wrapper = shallowMount(App, {
      propsData: {
        vulnerability,
        finding,
        createIssueUrl,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    mockAxios.reset();
    createFlash.mockReset();
  });

  describe('state dropdown', () => {
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
    it('renders properly', () => {
      expect(findCreateIssueButton().exists()).toBe(true);
    });

    it('calls create issue endpoint on click and redirects to new issue', () => {
      const issueUrl = '/group/project/issues/123';
      mockAxios.onPost(createIssueUrl).reply(200, {
        issue_url: issueUrl,
      });
      findCreateIssueButton().vm.$emit('click');
      return waitForPromises().then(() => {
        expect(mockAxios.history.post).toHaveLength(1);
        const [postRequest] = mockAxios.history.post;
        expect(postRequest.url).toBe(createIssueUrl);
        expect(JSON.parse(postRequest.data)).toMatchObject({
          vulnerability_feedback: {
            feedback_type: 'issue',
            category: vulnerability.report_type,
            project_fingerprint: finding.project_fingerprint,
            vulnerability_data: { ...vulnerability, category: vulnerability.report_type },
          },
        });
        expect(redirectTo).toHaveBeenCalledWith(issueUrl);
      });
    });

    it('shows an error message when issue creation fails', () => {
      mockAxios.onPost(createIssueUrl).reply(500);
      findCreateIssueButton().vm.$emit('click');
      return waitForPromises().then(() => {
        expect(mockAxios.history.post).toHaveLength(1);
        expect(createFlash).toHaveBeenCalledWith(
          'Something went wrong, could not create an issue.',
        );
      });
    });
  });
});
