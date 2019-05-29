import * as types from 'ee/dependencies/store/mutation_types';
import mutations from 'ee/dependencies/store/mutations';
import getInitialState from 'ee/dependencies/store/state';
import { REPORT_STATUS, SORT_ORDER } from 'ee/dependencies/store/constants';
import { TEST_HOST } from 'helpers/test_constants';

describe('Dependencies mutations', () => {
  let state;

  beforeEach(() => {
    state = getInitialState();
  });

  describe(types.SET_DEPENDENCIES_ENDPOINT, () => {
    it('sets the endpoint and download endpoint', () => {
      mutations[types.SET_DEPENDENCIES_ENDPOINT](state, TEST_HOST);

      expect(state.endpoint).toBe(TEST_HOST);
    });
  });

  describe(types.REQUEST_DEPENDENCIES, () => {
    beforeEach(() => {
      mutations[types.REQUEST_DEPENDENCIES](state);
    });

    it('sets isLoading to true', () => {
      expect(state.isLoading).toBe(true);
    });

    it('sets errorLoading to false', () => {
      expect(state.errorLoading).toBe(false);
    });
  });

  describe(types.RECEIVE_DEPENDENCIES_SUCCESS, () => {
    const dependencies = [];
    const pageInfo = {};
    const reportInfo = {
      status: REPORT_STATUS.jobFailed,
      job_path: 'foo',
    };

    beforeEach(() => {
      mutations[types.RECEIVE_DEPENDENCIES_SUCCESS](state, { dependencies, reportInfo, pageInfo });
    });

    it('sets isLoading to false', () => {
      expect(state.isLoading).toBe(false);
    });

    it('sets errorLoading to false', () => {
      expect(state.errorLoading).toBe(false);
    });

    it('sets dependencies', () => {
      expect(state.dependencies).toBe(dependencies);
    });

    it('sets pageInfo', () => {
      expect(state.pageInfo).toBe(pageInfo);
    });

    it('sets reportInfo', () => {
      expect(state.reportInfo).toEqual({
        status: REPORT_STATUS.jobFailed,
        jobPath: 'foo',
      });
    });

    it('sets initialized to true', () => {
      expect(state.initialized).toBe(true);
    });
  });

  describe(types.RECEIVE_DEPENDENCIES_ERROR, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_DEPENDENCIES_ERROR](state);
    });

    it('sets isLoading to false', () => {
      expect(state.isLoading).toBe(false);
    });

    it('sets errorLoading to true', () => {
      expect(state.errorLoading).toBe(true);
    });

    it('resets the dependencies list', () => {
      expect(state.dependencies).toEqual([]);
    });

    it('resets the pageInfo', () => {
      expect(state.pageInfo).toEqual({});
    });

    it('sets initialized to true', () => {
      expect(state.initialized).toBe(true);
    });

    it('resets the report info', () => {
      expect(state.reportInfo).toEqual({
        status: REPORT_STATUS.ok,
        jobPath: '',
      });
    });
  });

  describe(types.SET_SORT_FIELD, () => {
    it('sets the sort field', () => {
      const field = 'foo';
      mutations[types.SET_SORT_FIELD](state, field);

      expect(state.sortField).toBe(field);
    });
  });

  describe(types.TOGGLE_SORT_ORDER, () => {
    it('toggles the sort order', () => {
      const sortState = { sortOrder: SORT_ORDER.ascending };
      mutations[types.TOGGLE_SORT_ORDER](sortState);

      expect(sortState.sortOrder).toBe(SORT_ORDER.descending);

      mutations[types.TOGGLE_SORT_ORDER](sortState);

      expect(sortState.sortOrder).toBe(SORT_ORDER.ascending);
    });
  });
});
