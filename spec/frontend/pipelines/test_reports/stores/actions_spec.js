import MockAdapter from 'axios-mock-adapter';
import { getJSONFixture } from 'helpers/fixtures';
import axios from '~/lib/utils/axios_utils';
import * as actions from '~/pipelines/stores/test_reports/actions';
import * as types from '~/pipelines/stores/test_reports/mutation_types';
import { TEST_HOST } from '../../../helpers/test_constants';
import testAction from '../../../helpers/vuex_action_helper';
import createFlash from '~/flash';

jest.mock('~/flash.js');

describe('Actions TestReports Store', () => {
  let mock;
  let state;

  const testReports = getJSONFixture('pipelines/test_report.json');
  const summary = { total_count: 1 };

  const fullReportEndpoint = `${TEST_HOST}/test_reports.json`;
  const summaryEndpoint = `${TEST_HOST}/test_reports/summary.json`;
  const defaultState = {
    fullReportEndpoint,
    summaryEndpoint,
    testReports: {},
    selectedSuite: {},
    summary: {},
    hasFullReport: false,
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    state = { ...defaultState };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('fetch report summary', () => {
    beforeEach(() => {
      mock.onGet(summaryEndpoint).replyOnce(200, summary, {});
    });

    it('sets testReports and shows tests', done => {
      testAction(
        actions.fetchSummary,
        null,
        state,
        [{ type: types.SET_SUMMARY, payload: summary }],
        [{ type: 'setLoading', payload: true }, { type: 'setLoading', payload: false }],
        done,
      );
    });

    it('should create flash on API error', done => {
      testAction(
        actions.fetchSummary,
        null,
        {
          summaryEndpoint: null,
        },
        [],
        [{ type: 'setLoading', payload: true }, { type: 'setLoading', payload: false }],
        () => {
          expect(createFlash).toHaveBeenCalled();
          done();
        },
      );
    });
  });

  describe('fetch full report', () => {
    beforeEach(() => {
      mock.onGet(fullReportEndpoint).replyOnce(200, testReports, {});
    });

    it('sets testReports and shows tests', done => {
      testAction(
        actions.fetchFullReport,
        null,
        state,
        [{ type: types.SET_REPORTS, payload: testReports }],
        [{ type: 'setLoading', payload: true }, { type: 'setLoading', payload: false }],
        done,
      );
    });

    it('should create flash on API error', done => {
      testAction(
        actions.fetchFullReport,
        null,
        {
          fullReportEndpoint: null,
        },
        [],
        [{ type: 'setLoading', payload: true }, { type: 'setLoading', payload: false }],
        () => {
          expect(createFlash).toHaveBeenCalled();
          done();
        },
      );
    });
  });

  describe('set selected suite', () => {
    const selectedSuite = 1;

    describe('when state does not have full report', () => {
      it('sets selectedSuite', done => {
        testAction(
          actions.setSelectedSuite,
          selectedSuite,
          state,
          [{ type: types.SET_SELECTED_SUITE, payload: selectedSuite }],
          [{ type: 'fetchFullReport' }],
          done,
        );
      });
    });

    describe('when state has full report', () => {
      it('sets selectedSuite', done => {
        testAction(
          actions.setSelectedSuite,
          selectedSuite,
          { ...state, hasFullReport: true },
          [{ type: types.SET_SELECTED_SUITE, payload: selectedSuite }],
          [],
          done,
        );
      });
    });
  });

  describe('remove selected suite', () => {
    it('sets selectedSuiteIndex to null', done => {
      testAction(
        actions.removeSelectedSuite,
        {},
        state,
        [{ type: types.SET_SELECTED_SUITE, payload: null }],
        [],
        done,
      );
    });
  });

  describe('set loading', () => {
    it('sets isLoading to true', done => {
      testAction(
        actions.setLoading,
        true,
        state,
        [{ type: types.SET_LOADING, payload: true }],
        [],
        done,
      );
    });

    it('toggles isLoading to false', done => {
      testAction(
        actions.setLoading,
        false,
        { ...state, isLoading: true },
        [{ type: types.SET_LOADING, payload: false }],
        [],
        done,
      );
    });
  });
});
