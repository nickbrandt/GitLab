import * as types from 'ee/vue_shared/security_reports/store/modules/dependency_scanning/mutation_types';
import createState from 'ee/vue_shared/security_reports/store/modules/dependency_scanning/state';
import mutations from 'ee/vue_shared/security_reports/store/modules/dependency_scanning/mutations';
import {
  dependencyScanningIssuesOld,
  dependencyScanningIssuesBase,
  parsedDependencyScanningIssuesHead,
  parsedDependencyScanningBaseStore,
  parsedDependencyScanningIssuesStore,
} from '../../../mock_data';

describe('dependency scanning module mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('SET_HEAD_PATH', () => {
    it('should set dependency scanning head path', () => {
      mutations[types.SET_HEAD_PATH](state, 'head_path');

      expect(state.paths.head).toEqual('head_path');
    });
  });

  describe('SET_BASE_PATH', () => {
    it('should set dependency scanning base path', () => {
      mutations[types.SET_BASE_PATH](state, 'base_path');

      expect(state.paths.base).toEqual('base_path');
    });
  });

  describe('REQUEST_REPORTS', () => {
    it('should set dependency scanning loading flag to true', () => {
      mutations[types.REQUEST_REPORTS](state);

      expect(state.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_REPORTS', () => {
    const blobPath = { head: 'path', base: 'path' };

    beforeEach(() => {
      state.isLoading = true;
    });

    describe('with head and base', () => {
      it('should set new, fixed and all issues', () => {
        mutations[types.RECEIVE_REPORTS](state, {
          reports: {
            head: dependencyScanningIssuesOld,
            base: dependencyScanningIssuesBase,
          },
          blobPath,
        });

        expect(state.isLoading).toEqual(false);
        expect(state.newIssues).toEqual(parsedDependencyScanningIssuesHead);
        expect(state.resolvedIssues).toEqual(parsedDependencyScanningBaseStore);
      });
    });

    describe('with head', () => {
      it('should set new issues', () => {
        mutations[types.RECEIVE_REPORTS](state, {
          reports: { head: dependencyScanningIssuesOld },
          blobPath,
        });

        expect(state.isLoading).toEqual(false);
        expect(state.newIssues).toEqual(parsedDependencyScanningIssuesStore);
      });
    });
  });

  describe('RECEIVE_REPORTS_ERROR', () => {
    it('should set dependency scanning loading flag to false and error flag to true', () => {
      mutations[types.RECEIVE_REPORTS_ERROR](state);

      expect(state.isLoading).toEqual(false);
      expect(state.hasError).toEqual(true);
    });
  });

  describe('UPDATE_VULNERABILITY', () => {
    it('updates issue in the new issues list', () => {
      state.newIssues = parsedDependencyScanningIssuesHead;
      state.resolvedIssues = [];
      state.allIssues = [];
      const updatedIssue = {
        ...parsedDependencyScanningIssuesHead[0],
        foo: 'bar',
      };

      mutations[types.UPDATE_VULNERABILITY](state, updatedIssue);

      expect(state.newIssues[0]).toEqual(updatedIssue);
    });

    it('updates issue in the resolved issues list', () => {
      state.newIssues = [];
      state.resolvedIssues = parsedDependencyScanningIssuesHead;
      state.allIssues = [];
      const updatedIssue = {
        ...parsedDependencyScanningIssuesHead[0],
        foo: 'bar',
      };

      mutations[types.UPDATE_VULNERABILITY](state, updatedIssue);

      expect(state.resolvedIssues[0]).toEqual(updatedIssue);
    });

    it('updates issue in the all issues list', () => {
      state.newIssues = [];
      state.resolvedIssues = [];
      state.allIssues = parsedDependencyScanningIssuesHead;
      const updatedIssue = {
        ...parsedDependencyScanningIssuesHead[0],
        foo: 'bar',
      };

      mutations[types.UPDATE_VULNERABILITY](state, updatedIssue);

      expect(state.allIssues[0]).toEqual(updatedIssue);
    });
  });
});
