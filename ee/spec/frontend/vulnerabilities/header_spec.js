import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import UsersMockHelper from 'helpers/user_mock_data_helper';
import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import * as urlUtility from '~/lib/utils/url_utility';
import createFlash from '~/flash';
import Header from 'ee/vulnerabilities/components/header.vue';
import StatusDescription from 'ee/vulnerabilities/components/status_description.vue';
import ResolutionAlert from 'ee/vulnerabilities/components/resolution_alert.vue';
import VulnerabilityStateDropdown from 'ee/vulnerabilities/components/vulnerability_state_dropdown.vue';
import { VULNERABILITY_STATE_OBJECTS } from 'ee/vulnerabilities/constants';

const vulnerabilityStateEntries = Object.entries(VULNERABILITY_STATE_OBJECTS);
const mockAxios = new MockAdapter(axios);
jest.mock('~/flash');

describe('Vulnerability Header', () => {
  let wrapper;

  const defaultVulnerability = {
    id: 1,
    created_at: new Date().toISOString(),
    report_type: 'sast',
    state: 'detected',
  };

  const findingWithIssue = {
    description: 'description',
    identifiers: 'identifiers',
    links: 'links',
    location: 'location',
    name: 'name',
    issue_feedback: {
      issue_iid: 12,
    },
  };

  const findingWithoutIssue = {
    description: 'description',
    identifiers: 'identifiers',
    links: 'links',
    location: 'location',
    name: 'name',
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

  const createRandomUser = () => {
    const user = UsersMockHelper.createRandomUser();
    const url = Api.buildUrl(Api.userPath).replace(':id', user.id);
    mockAxios.onGet(url).replyOnce(200, user);

    return user;
  };

  const findCreateIssueButton = () => wrapper.find({ ref: 'create-issue-btn' });
  const findBadge = () => wrapper.find({ ref: 'badge' });
  const findResolutionAlert = () => wrapper.find(ResolutionAlert);
  const findStatusDescription = () => wrapper.find(StatusDescription);

  const createWrapper = (vulnerability = {}, finding = findingWithoutIssue) => {
    wrapper = shallowMount(Header, {
      propsData: {
        ...dataset,
        initialVulnerability: { ...defaultVulnerability, ...vulnerability },
        finding,
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

    it('does display if there is not an issue already created', () => {
      expect(findCreateIssueButton().exists()).toBe(true);
    });

    it('does not display if there is an issue already created', () => {
      createWrapper({}, findingWithIssue);
      expect(findCreateIssueButton().exists()).toBe(false);
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
              ...findingWithoutIssue,
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

  describe('status description', () => {
    it('the status description is rendered and passed the correct data', () => {
      const user = createRandomUser();
      const vulnerability = {
        ...defaultVulnerability,
        ...{ state: 'confirmed', confirmed_by_id: user.id },
      };

      createWrapper(vulnerability);

      return waitForPromises().then(() => {
        expect(findStatusDescription().exists()).toBe(true);
        expect(findStatusDescription().props()).toEqual({
          vulnerability,
          pipeline: dataset.pipeline,
          user,
          isLoadingVulnerability: wrapper.vm.isLoadingVulnerability,
          isLoadingUser: wrapper.vm.isLoadingUser,
        });
      });
    });
  });

  describe('when the vulnerability is no longer detected on the default branch', () => {
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

  describe('vulnerability user watcher', () => {
    it.each(vulnerabilityStateEntries)(
      `loads the correct user for the vulnerability state "%s"`,
      state => {
        const user = createRandomUser();
        createWrapper({ state, [`${state}_by_id`]: user.id });

        return waitForPromises().then(() => {
          expect(mockAxios.history.get.length).toBe(1);
          expect(findStatusDescription().props('user')).toEqual(user);
        });
      },
    );

    it('does not load a user if there is no user ID', () => {
      createWrapper({ state: 'detected' });

      return waitForPromises().then(() => {
        expect(mockAxios.history.get.length).toBe(0);
        expect(findStatusDescription().props('user')).toBeUndefined();
      });
    });

    it('will show an error when the user cannot be loaded', () => {
      createWrapper({ state: 'confirmed', confirmed_by_id: 1 });

      mockAxios.onGet().replyOnce(500);

      return waitForPromises().then(() => {
        expect(createFlash).toHaveBeenCalledTimes(1);
        expect(mockAxios.history.get.length).toBe(1);
      });
    });

    it('will set the isLoadingUser property correctly when the user is loading and finished loading', () => {
      const user = createRandomUser();
      createWrapper({ state: 'confirmed', confirmed_by_id: user.id });

      expect(findStatusDescription().props('isLoadingUser')).toBe(true);

      return waitForPromises().then(() => {
        expect(mockAxios.history.get.length).toBe(1);
        expect(findStatusDescription().props('isLoadingUser')).toBe(false);
      });
    });
  });
});
