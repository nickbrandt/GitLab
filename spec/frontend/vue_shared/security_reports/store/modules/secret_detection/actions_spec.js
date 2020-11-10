import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';

import createState from '~/vue_shared/security_reports/store/modules/secret_detection/state';
import * as types from '~/vue_shared/security_reports/store/modules/secret_detection/mutation_types';
import * as actions from '~/vue_shared/security_reports/store/modules/secret_detection/actions';
import axios from '~/lib/utils/axios_utils';

const diffEndpoint = 'diff-endpoint.json';
const blobPath = 'blob-path.json';
const reports = {
  base: 'base',
  head: 'head',
  enrichData: 'enrichData',
  diff: 'diff',
};
const error = 'Something went wrong';
const vulnerabilityFeedbackPath = 'vulnerability-feedback-path';
const rootState = { vulnerabilityFeedbackPath, blobPath };

let state;

describe('secret detection report actions', () => {
  beforeEach(() => {
    state = createState();
  });

  describe('setSecretScanningDiffEndpoint', () => {
    it(`should commit ${types.SET_SECRET_SCANNING_DIFF_ENDPOINT} with the correct path`, done => {
      testAction(
        actions.setSecretScanningDiffEndpoint,
        diffEndpoint,
        state,
        [
          {
            type: types.SET_SECRET_SCANNING_DIFF_ENDPOINT,
            payload: diffEndpoint,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestSecretScanningDiff', () => {
    it(`should commit ${types.REQUEST_SECRET_SCANNING_DIFF}`, done => {
      testAction(
        actions.requestSecretScanningDiff,
        {},
        state,
        [{ type: types.REQUEST_SECRET_SCANNING_DIFF }],
        [],
        done,
      );
    });
  });

  describe('receiveSecretScanningDiffSuccess', () => {
    it(`should commit ${types.RECEIVE_SECRET_SCANNING_DIFF_SUCCESS} with the correct response`, done => {
      testAction(
        actions.receiveSecretScanningDiffSuccess,
        reports,
        state,
        [
          {
            type: types.RECEIVE_SECRET_SCANNING_DIFF_SUCCESS,
            payload: reports,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveSecretScanningDiffError', () => {
    it(`should commit ${types.RECEIVE_SECRET_SCANNING_DIFF_ERROR} with the correct response`, done => {
      testAction(
        actions.receiveSecretScanningDiffError,
        error,
        state,
        [
          {
            type: types.RECEIVE_SECRET_SCANNING_DIFF_ERROR,
            payload: error,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchSecretScanningDiff', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
      state.paths.diffEndpoint = diffEndpoint;
      rootState.canReadVulnerabilityFeedback = true;
    });

    afterEach(() => {
      mock.restore();
    });

    describe('when diff and vulnerability feedback endpoints respond successfully', () => {
      beforeEach(() => {
        mock
          .onGet(diffEndpoint)
          .replyOnce(200, reports.diff)
          .onGet(vulnerabilityFeedbackPath)
          .replyOnce(200, reports.enrichData);
      });

      it('should dispatch the `receiveDiffSuccess` action', done => {
        const { diff, enrichData } = reports;
        testAction(
          actions.fetchSecretScanningDiff,
          {},
          { ...rootState, ...state },
          [],
          [
            { type: 'requestSecretScanningDiff' },
            {
              type: 'receiveSecretScanningDiffSuccess',
              payload: {
                diff,
                enrichData,
              },
            },
          ],
          done,
        );
      });
    });

    describe('when diff endpoint responds successfully and fetching vulnerability feedback is not authorized', () => {
      beforeEach(() => {
        rootState.canReadVulnerabilityFeedback = false;
        mock.onGet(diffEndpoint).replyOnce(200, reports.diff);
      });

      it('should dispatch the `receiveSecretScanningDiffSuccess` action with empty enrich data', done => {
        const { diff } = reports;
        const enrichData = [];
        testAction(
          actions.fetchSecretScanningDiff,
          {},
          { ...rootState, ...state },
          [],
          [
            { type: 'requestSecretScanningDiff' },
            {
              type: 'receiveSecretScanningDiffSuccess',
              payload: {
                diff,
                enrichData,
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
          .onGet(diffEndpoint)
          .replyOnce(200, reports.diff)
          .onGet(vulnerabilityFeedbackPath)
          .replyOnce(404);
      });

      it('should dispatch the `receiveSecretScanningDiffError` action', done => {
        testAction(
          actions.fetchSecretScanningDiff,
          {},
          { ...rootState, ...state },
          [],
          [{ type: 'requestSecretScanningDiff' }, { type: 'receiveSecretScanningDiffError' }],
          done,
        );
      });
    });

    describe('when the diff endpoint fails', () => {
      beforeEach(() => {
        mock
          .onGet(diffEndpoint)
          .replyOnce(404)
          .onGet(vulnerabilityFeedbackPath)
          .replyOnce(200, reports.enrichData);
      });

      it('should dispatch the `receiveSecretScanningDiffError` action', done => {
        testAction(
          actions.fetchSecretScanningDiff,
          {},
          { ...rootState, ...state },
          [],
          [{ type: 'requestSecretScanningDiff' }, { type: 'receiveSecretScanningDiffError' }],
          done,
        );
      });
    });
  });
});
