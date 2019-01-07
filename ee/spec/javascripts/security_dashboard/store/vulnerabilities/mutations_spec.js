import createState from 'ee/security_dashboard/store/modules/vulnerabilities/state';
import * as types from 'ee/security_dashboard/store/modules/vulnerabilities/mutation_types';
import mutations from 'ee/security_dashboard/store/modules/vulnerabilities/mutations';
import mockData from './data/mock_data_vulnerabilities.json';

describe('vulnerabilities module mutations', () => {
  describe('SET_VULNERABILITIES_ENDPOINT', () => {
    it('should set `vulnerabilitiesEndpoint` to `fakepath.json`', () => {
      const state = createState();
      const endpoint = 'fakepath.json';

      mutations[types.SET_VULNERABILITIES_ENDPOINT](state, endpoint);

      expect(state.vulnerabilitiesEndpoint).toEqual(endpoint);
    });
  });

  describe('REQUEST_VULNERABILITIES', () => {
    let state;

    beforeEach(() => {
      state = {
        ...createState(),
        errorLoadingVulnerabilities: true,
      };
      mutations[types.REQUEST_VULNERABILITIES](state);
    });

    it('should set `isLoadingVulnerabilities` to `true`', () => {
      expect(state.isLoadingVulnerabilities).toBeTruthy();
    });

    it('should set `errorLoadingVulnerabilities` to `false`', () => {
      expect(state.errorLoadingVulnerabilities).toBeFalsy();
    });
  });

  describe('RECEIVE_VULNERABILITIES_SUCCESS', () => {
    let payload;
    let state;

    beforeEach(() => {
      payload = {
        vulnerabilities: mockData,
        pageInfo: { a: 1, b: 2, c: 3 },
      };
      state = createState();
      mutations[types.RECEIVE_VULNERABILITIES_SUCCESS](state, payload);
    });

    it('should set `isLoadingVulnerabilities` to `false`', () => {
      expect(state.isLoadingVulnerabilities).toBeFalsy();
    });

    it('should set `pageInfo`', () => {
      expect(state.pageInfo).toBe(payload.pageInfo);
    });

    it('should set `vulnerabilities`', () => {
      expect(state.vulnerabilities).toBe(payload.vulnerabilities);
    });
  });

  describe('RECEIVE_VULNERABILITIES_ERROR', () => {
    it('should set `isLoadingVulnerabilities` to `false`', () => {
      const state = createState();

      mutations[types.RECEIVE_VULNERABILITIES_ERROR](state);

      expect(state.isLoadingVulnerabilities).toBeFalsy();
    });
  });

  describe('SET_VULNERABILITIES_COUNT_ENDPOINT', () => {
    it('should set `vulnerabilitiesCountEndpoint` to `fakepath.json`', () => {
      const state = createState();
      const endpoint = 'fakepath.json';

      mutations[types.SET_VULNERABILITIES_COUNT_ENDPOINT](state, endpoint);

      expect(state.vulnerabilitiesCountEndpoint).toEqual(endpoint);
    });
  });

  describe('REQUEST_VULNERABILITIES_COUNT', () => {
    let state;

    beforeEach(() => {
      state = {
        ...createState(),
        errorLoadingVulnerabilitiesCount: true,
      };
      mutations[types.REQUEST_VULNERABILITIES_COUNT](state);
    });

    it('should set `isLoadingVulnerabilitiesCount` to `true`', () => {
      expect(state.isLoadingVulnerabilitiesCount).toBeTruthy();
    });

    it('should set `errorLoadingVulnerabilitiesCount` to `false`', () => {
      expect(state.errorLoadingVulnerabilitiesCount).toBeFalsy();
    });
  });

  describe('RECEIVE_VULNERABILITIES_COUNT_SUCCESS', () => {
    let payload;
    let state;

    beforeEach(() => {
      payload = mockData;
      state = createState();
      mutations[types.RECEIVE_VULNERABILITIES_COUNT_SUCCESS](state, payload);
    });

    it('should set `isLoadingVulnerabilitiesCount` to `false`', () => {
      expect(state.isLoadingVulnerabilitiesCount).toBeFalsy();
    });

    it('should set `vulnerabilitiesCount`', () => {
      expect(state.vulnerabilitiesCount).toBe(payload);
    });
  });

  describe('RECEIVE_VULNERABILITIES_COUNT_ERROR', () => {
    it('should set `isLoadingVulnerabilitiesCount` to `false`', () => {
      const state = createState();

      mutations[types.RECEIVE_VULNERABILITIES_COUNT_ERROR](state);

      expect(state.isLoadingVulnerabilitiesCount).toBeFalsy();
    });
  });

  describe('SET_VULNERABILITIES_HISTORY_ENDPOINT', () => {
    it('should set `vulnerabilitiesHistoryEndpoint` to `fakepath.json`', () => {
      const state = createState();
      const endpoint = 'fakepath.json';

      mutations[types.SET_VULNERABILITIES_HISTORY_ENDPOINT](state, endpoint);

      expect(state.vulnerabilitiesHistoryEndpoint).toEqual(endpoint);
    });
  });

  describe('REQUEST_VULNERABILITIES_HISTORY', () => {
    let state;

    beforeEach(() => {
      state = {
        ...createState(),
        errorLoadingVulnerabilitiesHistory: true,
      };
      mutations[types.REQUEST_VULNERABILITIES_HISTORY](state);
    });

    it('should set `isLoadingVulnerabilitiesHistory` to `true`', () => {
      expect(state.isLoadingVulnerabilitiesHistory).toBeTruthy();
    });

    it('should set `errorLoadingVulnerabilitiesHistory` to `false`', () => {
      expect(state.errorLoadingVulnerabilitiesHistory).toBeFalsy();
    });
  });

  describe('RECEIVE_VULNERABILITIES_HISTORY_SUCCESS', () => {
    let payload;
    let state;

    beforeEach(() => {
      payload = mockData;
      state = createState();
      mutations[types.RECEIVE_VULNERABILITIES_HISTORY_SUCCESS](state, payload);
    });

    it('should set `isLoadingVulnerabilitiesHistory` to `false`', () => {
      expect(state.isLoadingVulnerabilitiesHistory).toBeFalsy();
    });

    it('should set `vulnerabilitiesHistory`', () => {
      expect(state.vulnerabilitiesHistory).toBe(payload);
    });
  });

  describe('RECEIVE_VULNERABILITIES_HISTORY_ERROR', () => {
    it('should set `isLoadingVulnerabilitiesHistory` to `false`', () => {
      const state = createState();

      mutations[types.RECEIVE_VULNERABILITIES_HISTORY_ERROR](state);

      expect(state.isLoadingVulnerabilitiesHistory).toBeFalsy();
    });
  });

  describe('SET_MODAL_DATA', () => {
    describe('with all the data', () => {
      const vulnerability = mockData[0];
      let payload;
      let state;

      beforeEach(() => {
        state = createState();
        payload = { vulnerability };
        mutations[types.SET_MODAL_DATA](state, payload);
      });

      it('should set the modal title', () => {
        expect(state.modal.title).toEqual(vulnerability.name);
      });

      it('should set the modal description', () => {
        expect(state.modal.data.description.value).toEqual(vulnerability.description);
      });

      it('should set the modal project', () => {
        expect(state.modal.data.project.value).toEqual(vulnerability.project.full_name);
        expect(state.modal.data.project.url).toEqual(vulnerability.project.full_path);
      });

      it('should set the modal file', () => {
        expect(state.modal.data.file.value).toEqual(vulnerability.location.file);
      });

      it('should set the modal identifiers', () => {
        expect(state.modal.data.identifiers.value).toEqual(vulnerability.identifiers);
      });

      it('should set the modal severity', () => {
        expect(state.modal.data.severity.value).toEqual(vulnerability.severity);
      });

      it('should set the modal confidence', () => {
        expect(state.modal.data.confidence.value).toEqual(vulnerability.confidence);
      });

      it('should set the modal class', () => {
        expect(state.modal.data.className.value).toEqual(vulnerability.location.class);
      });

      it('should set the modal links', () => {
        expect(state.modal.data.links.value).toEqual(vulnerability.links);
      });

      it('should set the modal instances', () => {
        expect(state.modal.data.instances.value).toEqual(vulnerability.instances);
      });

      it('should set the modal vulnerability', () => {
        expect(state.modal.vulnerability).toEqual(vulnerability);
      });
    });

    describe('with irregular data', () => {
      const vulnerability = mockData[0];
      let state;

      beforeEach(() => {
        state = createState();
      });

      it('should set isDismissed when the vulnerabilitiy is dismissed', () => {
        const payload = {
          vulnerability: { ...vulnerability, dismissal_feedback: 'I am dismissed' },
        };
        mutations[types.SET_MODAL_DATA](state, payload);

        expect(state.modal.vulnerability.isDismissed).toEqual(true);
      });

      it('should set hasIssue when the vulnerabilitiy has a related issue', () => {
        const payload = { vulnerability: { ...vulnerability, issue_feedback: 'I am an issue' } };
        mutations[types.SET_MODAL_DATA](state, payload);

        expect(state.modal.vulnerability.hasIssue).toEqual(true);
      });

      it('should nullify the modal links', () => {
        const payload = { vulnerability: { ...vulnerability, links: [] } };
        mutations[types.SET_MODAL_DATA](state, payload);

        expect(state.modal.data.links.value).toEqual(null);
      });

      it('should nullify the instances', () => {
        const payload = { vulnerability: { ...vulnerability, instances: [] } };
        mutations[types.SET_MODAL_DATA](state, payload);

        expect(state.modal.data.instances.value).toEqual(null);
      });
    });
  });

  describe('REQUEST_CREATE_ISSUE', () => {
    let state;

    beforeEach(() => {
      state = createState();
      mutations[types.REQUEST_CREATE_ISSUE](state);
    });

    it('should set isCreatingIssue to true', () => {
      expect(state.isCreatingIssue).toBe(true);
    });

    it('should set isCreatingNewIssue in the modal data to true', () => {
      expect(state.modal.isCreatingNewIssue).toBe(true);
    });

    it('should nullify the error state on the modal', () => {
      expect(state.modal.error).toBeNull();
    });
  });

  describe('RECEIVE_CREATE_ISSUE_SUCCESS', () => {
    it('should fire the visitUrl function on the issue URL', () => {
      const state = createState();
      const payload = { issue_url: 'fakepath.html' };
      const visitUrl = spyOnDependency(mutations, 'visitUrl');
      mutations[types.RECEIVE_CREATE_ISSUE_SUCCESS](state, payload);

      expect(visitUrl).toHaveBeenCalledWith(payload.issue_url);
    });
  });

  describe('RECEIVE_CREATE_ISSUE_ERROR', () => {
    let state;

    beforeEach(() => {
      state = createState();
      mutations[types.RECEIVE_CREATE_ISSUE_ERROR](state);
    });

    it('should set isCreatingIssue to false', () => {
      expect(state.isCreatingIssue).toBe(false);
    });

    it('should set isCreatingNewIssue in the modal data to false', () => {
      expect(state.modal.isCreatingNewIssue).toBe(false);
    });

    it('should set the error state on the modal', () => {
      expect(state.modal.error).toEqual('There was an error creating the issue');
    });
  });

  describe('REQUEST_DISMISS_VULNERABILITY', () => {
    let state;

    beforeEach(() => {
      state = createState();
      mutations[types.REQUEST_DISMISS_VULNERABILITY](state);
    });

    it('should set isDismissingVulnerability to true', () => {
      expect(state.isDismissingVulnerability).toBe(true);
    });

    it('should set isDismissingVulnerability in the modal data to true', () => {
      expect(state.modal.isDismissingVulnerability).toBe(true);
    });

    it('should nullify the error state on the modal', () => {
      expect(state.modal.error).toBeNull();
    });
  });

  describe('RECEIVE_DISMISS_VULNERABILITY_SUCCESS', () => {
    let state;
    let payload;
    let vulnerability;
    let data;

    beforeEach(() => {
      state = createState();
      state.vulnerabilities = mockData;
      [vulnerability] = mockData;
      data = { name: 'dismissal feedback' };
      payload = { id: vulnerability.id, data };
      mutations[types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS](state, payload);
    });

    it('should set the dismissal feedback on the passed vulnerability', () => {
      expect(vulnerability.dismissal_feedback).toEqual(data);
    });

    it('should set isDismissingVulnerability to false', () => {
      expect(state.isDismissingVulnerability).toBe(false);
    });

    it('should set isDismissingVulnerability on the modal to false', () => {
      expect(state.modal.isDismissingVulnerability).toBe(false);
    });

    it('shoulfd set isDissmissed on the modal vulnerability to be true', () => {
      expect(state.modal.vulnerability.isDismissed).toBe(true);
    });
  });

  describe('RECEIVE_DISMISS_VULNERABILITY_ERROR', () => {
    let state;

    beforeEach(() => {
      state = createState();
      mutations[types.RECEIVE_DISMISS_VULNERABILITY_ERROR](state);
    });

    it('should set isDismissingVulnerability to false', () => {
      expect(state.isDismissingVulnerability).toBe(false);
    });

    it('should set isDismissingVulnerability in the modal data to false', () => {
      expect(state.modal.isDismissingVulnerability).toBe(false);
    });

    it('should set the error state on the modal', () => {
      expect(state.modal.error).toEqual('There was an error dismissing the vulnerability.');
    });
  });

  describe('REQUEST_REVERT_DISMISSAL', () => {
    let state;

    beforeEach(() => {
      state = createState();
      mutations[types.REQUEST_REVERT_DISMISSAL](state);
    });

    it('should set isDismissingVulnerability to true', () => {
      expect(state.isDismissingVulnerability).toBe(true);
    });

    it('should set isDismissingVulnerability in the modal data to true', () => {
      expect(state.modal.isDismissingVulnerability).toBe(true);
    });

    it('should nullify the error state on the modal', () => {
      expect(state.modal.error).toBeNull();
    });
  });

  describe('RECEIVE_REVERT_DISMISSAL_SUCCESS', () => {
    let state;
    let payload;
    let vulnerability;

    beforeEach(() => {
      state = createState();
      state.vulnerabilities = mockData;
      [vulnerability] = mockData;
      payload = { id: vulnerability.id };
      mutations[types.RECEIVE_REVERT_DISMISSAL_SUCCESS](state, payload);
    });

    it('should set the dismissal feedback on the passed vulnerability', () => {
      expect(vulnerability.dismissal_feedback).toBeNull();
    });

    it('should set isDismissingVulnerability to false', () => {
      expect(state.isDismissingVulnerability).toBe(false);
    });

    it('should set isDismissingVulnerability on the modal to false', () => {
      expect(state.modal.isDismissingVulnerability).toBe(false);
    });

    it('should set isDissmissed on the modal vulnerability to be false', () => {
      expect(state.modal.vulnerability.isDismissed).toBe(false);
    });
  });

  describe('RECEIVE_REVERT_DISMISSAL_ERROR', () => {
    let state;

    beforeEach(() => {
      state = createState();
      mutations[types.RECEIVE_REVERT_DISMISSAL_ERROR](state);
    });

    it('should set isDismissingVulnerability to false', () => {
      expect(state.isDismissingVulnerability).toBe(false);
    });

    it('should set isDismissingVulnerability in the modal data to false', () => {
      expect(state.modal.isDismissingVulnerability).toBe(false);
    });

    it('should set the error state on the modal', () => {
      expect(state.modal.error).toEqual('There was an error reverting the dismissal.');
    });
  });
});
