import initialState from 'ee/security_dashboard/store/modules/vulnerabilities/state';
import * as types from 'ee/security_dashboard/store/modules/vulnerabilities/mutation_types';
import mutations from 'ee/security_dashboard/store/modules/vulnerabilities/mutations';

describe('vulnerabilities module mutations', () => {
  describe('SET_VULNERABILITIES_ENDPOINT', () => {
    it('should set `vulnerabilitiesEndpoint` to `fakepath.json`', () => {
      const state = initialState;
      const endpoint = 'fakepath.json';

      mutations[types.SET_VULNERABILITIES_ENDPOINT](state, endpoint);

      expect(state.vulnerabilitiesEndpoint).toEqual(endpoint);
    });
  });

  describe('REQUEST_VULNERABILITIES', () => {
    let state;

    beforeEach(() => {
      state = {
        ...initialState,
        hasError: true,
      };
      mutations[types.REQUEST_VULNERABILITIES](state);
    });

    it('should set `isLoadingVulnerabilities` to `true`', () => {
      expect(state.isLoadingVulnerabilities).toBeTruthy();
    });

    it('should set `hasError` to `false`', () => {
      expect(state.hasError).toBeFalsy();
    });
  });

  describe('RECEIVE_VULNERABILITIES_SUCCESS', () => {
    let payload;
    let state;

    beforeEach(() => {
      payload = {
        vulnerabilities: [1, 2, 3, 4, 5],
        pageInfo: { a: 1, b: 2, c: 3 },
      };
      state = initialState;
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
      const state = initialState;

      mutations[types.RECEIVE_VULNERABILITIES_ERROR](state);

      expect(state.isLoadingVulnerabilities).toBeFalsy();
    });
  });

  describe('SET_VULNERABILITIES_COUNT_ENDPOINT', () => {
    it('should set `vulnerabilitiesCountEndpoint` to `fakepath.json`', () => {
      const state = initialState;
      const endpoint = 'fakepath.json';

      mutations[types.SET_VULNERABILITIES_COUNT_ENDPOINT](state, endpoint);

      expect(state.vulnerabilitiesCountEndpoint).toEqual(endpoint);
    });
  });

  describe('REQUEST_VULNERABILITIES_COUNT', () => {
    let state;

    beforeEach(() => {
      state = {
        ...initialState,
        hasError: true,
      };
      mutations[types.REQUEST_VULNERABILITIES_COUNT](state);
    });

    it('should set `isLoadingVulnerabilitiesCount` to `true`', () => {
      expect(state.isLoadingVulnerabilitiesCount).toBeTruthy();
    });

    it('should set `hasError` to `false`', () => {
      expect(state.hasError).toBeFalsy();
    });
  });

  describe('RECEIVE_VULNERABILITIES_COUNT_SUCCESS', () => {
    let payload;
    let state;

    beforeEach(() => {
      payload = { a: 1, b: 2, c: 3 };
      state = initialState;
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
      const state = initialState;

      mutations[types.RECEIVE_VULNERABILITIES_COUNT_ERROR](state);

      expect(state.isLoadingVulnerabilitiesCount).toBeFalsy();
    });
  });
});
