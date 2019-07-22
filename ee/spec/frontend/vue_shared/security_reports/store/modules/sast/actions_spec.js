import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import testAction from 'helpers/vuex_action_helper';

import createState from 'ee/vue_shared/security_reports/store/modules/sast/state';
import * as types from 'ee/vue_shared/security_reports/store/modules/sast/mutation_types';
import * as actions from 'ee/vue_shared/security_reports/store/modules/sast/actions';

const headPath = 'head-path.json';
const basePath = 'base-path.json';
const blobPath = 'blob-path.json';
const reports = {
  base: 'base',
  head: 'head',
  enrichData: 'enrichData',
};
const error = 'Something went wrong';
const issue = {};
const vulnerabilityFeedbackPath = 'vulnerability-feedback-path';
const rootState = { vulnerabilityFeedbackPath, blobPath };

let state;

describe('sast report actions', () => {
  beforeEach(() => {
    state = createState();
  });

  describe('setHeadPath', () => {
    it(`should commit ${types.SET_HEAD_PATH} with the correct path`, done => {
      testAction(
        actions.setHeadPath,
        headPath,
        state,
        [
          {
            type: types.SET_HEAD_PATH,
            payload: headPath,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setBasePath', () => {
    it(`should commit ${types.SET_BASE_PATH} with the correct path`, done => {
      testAction(
        actions.setBasePath,
        basePath,
        state,
        [
          {
            type: types.SET_BASE_PATH,
            payload: basePath,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestReports', () => {
    it(`should commit ${types.REQUEST_REPORTS}`, done => {
      testAction(actions.requestReports, {}, state, [{ type: types.REQUEST_REPORTS }], [], done);
    });
  });

  describe('receiveReports', () => {
    it(`should commit ${types.RECEIVE_REPORTS} with the correct response`, done => {
      testAction(
        actions.receiveReports,
        reports,
        state,
        [
          {
            type: types.RECEIVE_REPORTS,
            payload: reports,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveError', () => {
    it(`should commit ${types.RECEIVE_REPORTS_ERROR} with the correct response`, done => {
      testAction(
        actions.receiveError,
        error,
        state,
        [
          {
            type: types.RECEIVE_REPORTS_ERROR,
            payload: error,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchReports', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
      state.paths.head = headPath;
      state.paths.base = basePath;
    });

    afterEach(() => {
      mock.restore();
    });

    describe('when everything goes according to plan', () => {
      beforeEach(() => {
        mock
          .onGet(headPath)
          .replyOnce(200, reports.head)
          .onGet(basePath)
          .replyOnce(200, reports.base)
          .onGet(vulnerabilityFeedbackPath)
          .replyOnce(200, reports.enrichData);
      });

      it('should dispatch the `receiveReports` action', done => {
        testAction(
          actions.fetchReports,
          {},
          { ...rootState, ...state },
          [],
          [
            { type: 'requestReports' },
            {
              type: 'receiveReports',
              payload: {
                blobPath,
                reports,
              },
            },
          ],
          done,
        );
      });
    });

    describe('when the vulnerability feedback endpoint fails', () => {
      beforeEach(() => {
        mock
          .onGet(headPath)
          .replyOnce(200, reports.head)
          .onGet(basePath)
          .replyOnce(200, reports.base)
          .onGet(vulnerabilityFeedbackPath)
          .replyOnce(404);
      });

      it('should dispatch the `receiveError` action', done => {
        testAction(
          actions.fetchReports,
          {},
          { ...rootState, ...state },
          [],
          [{ type: 'requestReports' }, { type: 'receiveError' }],
          done,
        );
      });
    });
  });

  describe('updateVulnerability', () => {
    it(`should commit ${types.UPDATE_VULNERABILITY} with the correct response`, done => {
      testAction(
        actions.updateVulnerability,
        issue,
        state,
        [
          {
            type: types.UPDATE_VULNERABILITY,
            payload: issue,
          },
        ],
        [],
        done,
      );
    });
  });
});
