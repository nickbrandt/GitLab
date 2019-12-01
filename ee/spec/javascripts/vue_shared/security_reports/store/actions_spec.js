import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import actions, {
  setHeadBlobPath,
  setBaseBlobPath,
  setVulnerabilityFeedbackPath,
  setVulnerabilityFeedbackHelpPath,
  setPipelineId,
  setCanCreateIssuePermission,
  setCanCreateFeedbackPermission,
  setSastContainerHeadPath,
  setSastContainerBasePath,
  requestSastContainerReports,
  receiveSastContainerReports,
  receiveSastContainerError,
  fetchSastContainerReports,
  setDastHeadPath,
  setDastBasePath,
  requestDastReports,
  receiveDastReports,
  receiveDastError,
  fetchDastReports,
  setDependencyScanningHeadPath,
  setDependencyScanningBasePath,
  requestDependencyScanningReports,
  receiveDependencyScanningError,
  receiveDependencyScanningReports,
  fetchDependencyScanningReports,
  openModal,
  setModalData,
  requestDismissVulnerability,
  receiveDismissVulnerability,
  receiveDismissVulnerabilityError,
  dismissVulnerability,
  revertDismissVulnerability,
  requestCreateIssue,
  receiveCreateIssue,
  receiveCreateIssueError,
  createNewIssue,
  downloadPatch,
  requestCreateMergeRequest,
  receiveCreateMergeRequestSuccess,
  receiveCreateMergeRequestError,
  createMergeRequest,
  updateDependencyScanningIssue,
  updateContainerScanningIssue,
  updateDastIssue,
  addDismissalComment,
  receiveAddDismissalCommentError,
  receiveAddDismissalCommentSuccess,
  requestAddDismissalComment,
  deleteDismissalComment,
  receiveDeleteDismissalCommentError,
  receiveDeleteDismissalCommentSuccess,
  requestDeleteDismissalComment,
  showDismissalDeleteButtons,
  hideDismissalDeleteButtons,
  setSastContainerDiffEndpoint,
  receiveSastContainerDiffSuccess,
  receiveSastContainerDiffError,
  fetchSastContainerDiff,
  setDependencyScanningDiffEndpoint,
  receiveDependencyScanningDiffSuccess,
  receiveDependencyScanningDiffError,
  fetchDependencyScanningDiff,
  setDastDiffEndpoint,
  receiveDastDiffSuccess,
  receiveDastDiffError,
  fetchDastDiff,
} from 'ee/vue_shared/security_reports/store/actions';
import * as types from 'ee/vue_shared/security_reports/store/mutation_types';
import state from 'ee/vue_shared/security_reports/store/state';
import testAction from 'spec/helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import {
  sastIssues,
  sastIssuesBase,
  dast,
  dastBase,
  dockerReport,
  dockerBaseReport,
  sastFeedbacks,
  dastFeedbacks,
  containerScanningFeedbacks,
  dependencyScanningFeedbacks,
} from '../mock_data';

const createVulnerability = options => ({
  ...options,
});

const createNonDismissedVulnerability = options =>
  createVulnerability({
    ...options,
    isDismissed: false,
    dismissalFeedback: null,
  });

const createDismissedVulnerability = options =>
  createVulnerability({
    ...options,
    isDismissed: true,
  });

describe('security reports actions', () => {
  let mockedState;
  let mock;

  beforeEach(() => {
    mockedState = state();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setHeadBlobPath', () => {
    it('should commit set head blob path', done => {
      testAction(
        setHeadBlobPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_HEAD_BLOB_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setBaseBlobPath', () => {
    it('should commit set head blob path', done => {
      testAction(
        setBaseBlobPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_BASE_BLOB_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setVulnerabilityFeedbackPath', () => {
    it('should commit set vulnerabulity feedback path', done => {
      testAction(
        setVulnerabilityFeedbackPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_VULNERABILITY_FEEDBACK_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setVulnerabilityFeedbackHelpPath', () => {
    it('should commit set vulnerabulity feedback help path', done => {
      testAction(
        setVulnerabilityFeedbackHelpPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_VULNERABILITY_FEEDBACK_HELP_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setPipelineId', () => {
    it('should commit set vulnerability feedback path', done => {
      testAction(
        setPipelineId,
        123,
        mockedState,
        [
          {
            type: types.SET_PIPELINE_ID,
            payload: 123,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setCanCreateIssuePermission', () => {
    it('should commit set can create issue permission', done => {
      testAction(
        setCanCreateIssuePermission,
        true,
        mockedState,
        [
          {
            type: types.SET_CAN_CREATE_ISSUE_PERMISSION,
            payload: true,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setCanCreateFeedbackPermission', () => {
    it('should commit set can create feedback permission', done => {
      testAction(
        setCanCreateFeedbackPermission,
        true,
        mockedState,
        [
          {
            type: types.SET_CAN_CREATE_FEEDBACK_PERMISSION,
            payload: true,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setSastContainerHeadPath', () => {
    it('should commit set head blob path', done => {
      testAction(
        setSastContainerHeadPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_SAST_CONTAINER_HEAD_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setSastContainerBasePath', () => {
    it('should commit set head blob path', done => {
      testAction(
        setSastContainerBasePath,
        'path',
        mockedState,
        [
          {
            type: types.SET_SAST_CONTAINER_BASE_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestSastContainerReports', () => {
    it('should commit request mutation', done => {
      testAction(
        requestSastContainerReports,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_SAST_CONTAINER_REPORTS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveSastContainerReports', () => {
    it('should commit sast receive mutation', done => {
      testAction(
        receiveSastContainerReports,
        {},
        mockedState,
        [
          {
            type: types.RECEIVE_SAST_CONTAINER_REPORTS,
            payload: {},
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveSastContainerError', () => {
    it('should commit sast error mutation', done => {
      const error = new Error('test');

      testAction(
        receiveSastContainerError,
        error,
        mockedState,
        [
          {
            type: types.RECEIVE_SAST_CONTAINER_ERROR,
            payload: error,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchSastContainerReports', () => {
    describe('with head and base', () => {
      it('should dispatch `receiveSastContainerReports`', done => {
        mock.onGet('foo').reply(200, dockerReport);
        mock.onGet('bar').reply(200, dockerBaseReport);
        mock
          .onGet('vulnerabilities_path', {
            params: {
              category: 'container_scanning',
            },
          })
          .reply(200, containerScanningFeedbacks);

        mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_path';
        mockedState.sastContainer.paths.head = 'foo';
        mockedState.sastContainer.paths.base = 'bar';

        testAction(
          fetchSastContainerReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestSastContainerReports',
            },
            {
              type: 'receiveSastContainerReports',
              payload: {
                head: dockerReport,
                base: dockerBaseReport,
                enrichData: containerScanningFeedbacks,
              },
            },
          ],
          done,
        );
      });

      it('should dispatch `receiveSastContainerError`', done => {
        mock.onGet('foo').reply(500, {});
        mockedState.sastContainer.paths.head = 'foo';
        mockedState.sastContainer.paths.base = 'bar';

        testAction(
          fetchSastContainerReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestSastContainerReports',
            },
            {
              type: 'receiveSastContainerError',
            },
          ],
          done,
        );
      });
    });

    describe('with head', () => {
      it('should dispatch `receiveSastContainerReports`', done => {
        mock.onGet('foo').reply(200, dockerReport);
        mock
          .onGet('vulnerabilities_path', {
            params: {
              category: 'container_scanning',
            },
          })
          .reply(200, containerScanningFeedbacks);

        mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_path';

        mockedState.sastContainer.paths.head = 'foo';

        testAction(
          fetchSastContainerReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestSastContainerReports',
            },
            {
              type: 'receiveSastContainerReports',
              payload: { head: dockerReport, base: null, enrichData: containerScanningFeedbacks },
            },
          ],
          done,
        );
      });

      it('should dispatch `receiveSastContainerError`', done => {
        mock.onGet('foo').reply(500, {});
        mockedState.sastContainer.paths.head = 'foo';

        testAction(
          fetchSastContainerReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestSastContainerReports',
            },
            {
              type: 'receiveSastContainerError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('setDastHeadPath', () => {
    it('should commit set head blob path', done => {
      testAction(
        setDastHeadPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_DAST_HEAD_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setDastBasePath', () => {
    it('should commit set head blob path', done => {
      testAction(
        setDastBasePath,
        'path',
        mockedState,
        [
          {
            type: types.SET_DAST_BASE_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestDastReports', () => {
    it('should commit request mutation', done => {
      testAction(
        requestDastReports,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_DAST_REPORTS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDastReports', () => {
    it('should commit sast receive mutation', done => {
      testAction(
        receiveDastReports,
        {},
        mockedState,
        [
          {
            type: types.RECEIVE_DAST_REPORTS,
            payload: {},
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDastError', () => {
    it('should commit sast error mutation', done => {
      const error = new Error('test');

      testAction(
        receiveDastError,
        error,
        mockedState,
        [
          {
            type: types.RECEIVE_DAST_ERROR,
            payload: error,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchDastReports', () => {
    describe('with head and base', () => {
      it('should dispatch `receiveDastReports`', done => {
        mock.onGet('foo').reply(200, dast);
        mock.onGet('bar').reply(200, dastBase);

        mock
          .onGet('vulnerabilities_path', {
            params: {
              category: 'dast',
            },
          })
          .reply(200, dastFeedbacks);

        mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_path';
        mockedState.dast.paths.head = 'foo';
        mockedState.dast.paths.base = 'bar';

        testAction(
          fetchDastReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDastReports',
            },
            {
              type: 'receiveDastReports',
              payload: { head: dast, base: dastBase, enrichData: dastFeedbacks },
            },
          ],
          done,
        );
      });

      it('should dispatch `receiveDastError`', done => {
        mock.onGet('foo').reply(500, {});
        mockedState.dast.paths.head = 'foo';
        mockedState.dast.paths.base = 'bar';

        testAction(
          fetchDastReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDastReports',
            },
            {
              type: 'receiveDastError',
            },
          ],
          done,
        );
      });
    });

    describe('with head', () => {
      it('should dispatch `receiveSastContainerReports`', done => {
        mock.onGet('foo').reply(200, dast);
        mock
          .onGet('vulnerabilities_path', {
            params: {
              category: 'dast',
            },
          })
          .reply(200, dastFeedbacks);

        mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_path';
        mockedState.dast.paths.head = 'foo';

        testAction(
          fetchDastReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDastReports',
            },
            {
              type: 'receiveDastReports',
              payload: { head: dast, base: null, enrichData: dastFeedbacks },
            },
          ],
          done,
        );
      });

      it('should dispatch `receiveDastError`', done => {
        mock.onGet('foo').reply(500, {});
        mockedState.dast.paths.head = 'foo';

        testAction(
          fetchDastReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDastReports',
            },
            {
              type: 'receiveDastError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('setDependencyScanningHeadPath', () => {
    it('should commit set head blob path', done => {
      testAction(
        setDependencyScanningHeadPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_DEPENDENCY_SCANNING_HEAD_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setDependencyScanningBasePath', () => {
    it('should commit set head blob path', done => {
      testAction(
        setDependencyScanningBasePath,
        'path',
        mockedState,
        [
          {
            type: types.SET_DEPENDENCY_SCANNING_BASE_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestDependencyScanningReports', () => {
    it('should commit request mutation', done => {
      testAction(
        requestDependencyScanningReports,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_DEPENDENCY_SCANNING_REPORTS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDependencyScanningReports', () => {
    it('should commit sast receive mutation', done => {
      testAction(
        receiveDependencyScanningReports,
        {},
        mockedState,
        [
          {
            type: types.RECEIVE_DEPENDENCY_SCANNING_REPORTS,
            payload: {},
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDependencyScanningError', () => {
    it('should commit dependency scanning error mutation', done => {
      const error = new Error('test');

      testAction(
        receiveDependencyScanningError,
        error,
        mockedState,
        [
          {
            type: types.RECEIVE_DEPENDENCY_SCANNING_ERROR,
            payload: error,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchDependencyScanningReports', () => {
    describe('with head and base', () => {
      it('should dispatch `receiveDependencyScanningReports`', done => {
        mock.onGet('foo').reply(200, sastIssues);
        mock.onGet('bar').reply(200, sastIssuesBase);
        mock
          .onGet('vulnerabilities_path', {
            params: {
              category: 'dependency_scanning',
            },
          })
          .reply(200, sastFeedbacks);

        mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_path';
        mockedState.dependencyScanning.paths.head = 'foo';
        mockedState.dependencyScanning.paths.base = 'bar';

        testAction(
          fetchDependencyScanningReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDependencyScanningReports',
            },
            {
              type: 'receiveDependencyScanningReports',
              payload: { head: sastIssues, base: sastIssuesBase, enrichData: sastFeedbacks },
            },
          ],
          done,
        );
      });

      it('should dispatch `receiveDependencyScanningError`', done => {
        mock.onGet('foo').reply(500, {});
        mockedState.dependencyScanning.paths.head = 'foo';
        mockedState.dependencyScanning.paths.base = 'bar';

        testAction(
          fetchDependencyScanningReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDependencyScanningReports',
            },
            {
              type: 'receiveDependencyScanningError',
            },
          ],
          done,
        );
      });
    });

    describe('with head', () => {
      it('should dispatch `receiveDependencyScanningReports`', done => {
        mock.onGet('foo').reply(200, sastIssues);
        mock
          .onGet('vulnerabilities_path', {
            params: {
              category: 'dependency_scanning',
            },
          })
          .reply(200, sastFeedbacks);

        mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_path';
        mockedState.dependencyScanning.paths.head = 'foo';

        testAction(
          fetchDependencyScanningReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDependencyScanningReports',
            },
            {
              type: 'receiveDependencyScanningReports',
              payload: { head: sastIssues, base: null, enrichData: sastFeedbacks },
            },
          ],
          done,
        );
      });

      it('should dispatch `receiveDependencyScanningError`', done => {
        mock.onGet('foo').reply(500, {});
        mockedState.dependencyScanning.paths.head = 'foo';

        testAction(
          fetchDependencyScanningReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDependencyScanningReports',
            },
            {
              type: 'receiveDependencyScanningError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('openModal', () => {
    it('dispatches setModalData action', done => {
      testAction(
        openModal,
        { issue: { id: 1 }, status: 'failed' },
        mockedState,
        [],
        [
          {
            type: 'setModalData',
            payload: { issue: { id: 1 }, status: 'failed' },
          },
        ],
        done,
      );
    });
  });

  describe('setModalData', () => {
    it('commits set issue modal data', done => {
      testAction(
        setModalData,
        { issue: { id: 1 }, status: 'success' },
        mockedState,
        [
          {
            type: types.SET_ISSUE_MODAL_DATA,
            payload: { issue: { id: 1 }, status: 'success' },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestDismissVulnerability', () => {
    it('commits request dismiss issue', done => {
      testAction(
        requestDismissVulnerability,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_DISMISS_VULNERABILITY,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDismissVulnerability', () => {
    it(`should pass the payload to the ${types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS} mutation`, done => {
      const payload = createDismissedVulnerability();

      testAction(
        receiveDismissVulnerability,
        payload,
        mockedState,
        [
          {
            type: types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDismissVulnerabilityError', () => {
    it('commits receive dismiss issue error with payload', done => {
      testAction(
        receiveDismissVulnerabilityError,
        'error',
        mockedState,
        [
          {
            type: types.RECEIVE_DISMISS_VULNERABILITY_ERROR,
            payload: 'error',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('dismissVulnerability', () => {
    describe('with success', () => {
      let payload;
      let dismissalFeedback;

      beforeEach(() => {
        dismissalFeedback = {
          foo: 'bar',
        };
        payload = createDismissedVulnerability({
          ...mockedState.modal.vulnerability,
          dismissalFeedback,
        });
        mock.onPost('dismiss_vulnerability_path').reply(200, dismissalFeedback);
        mockedState.createVulnerabilityFeedbackDismissalPath = 'dismiss_vulnerability_path';
      });

      it(`should dispatch ${types.receiveDismissVulnerability}`, done => {
        testAction(
          dismissVulnerability,
          payload,
          mockedState,
          [],
          [
            {
              type: 'requestDismissVulnerability',
            },
            {
              type: 'closeDismissalCommentBox',
            },
            {
              type: 'receiveDismissVulnerability',
              payload,
            },
          ],
          done,
        );
      });

      it('show dismiss vulnerability toast message', done => {
        spyOn(Vue.toasted, 'show');

        const checkToastMessage = () => {
          expect(Vue.toasted.show).toHaveBeenCalledTimes(1);
          done();
        };

        testAction(
          dismissVulnerability,
          payload,
          mockedState,
          [],
          [
            {
              type: 'requestDismissVulnerability',
            },
            {
              type: 'closeDismissalCommentBox',
            },
            {
              type: 'receiveDismissVulnerability',
              payload,
            },
          ],
          checkToastMessage,
        );
      });
    });

    it('with error should dispatch `receiveDismissVulnerabilityError`', done => {
      mock.onPost('dismiss_vulnerability_path').reply(500, {});
      mockedState.vulnerabilityFeedbackPath = 'dismiss_vulnerability_path';

      testAction(
        dismissVulnerability,
        null,
        mockedState,
        [],
        [
          {
            type: 'requestDismissVulnerability',
          },
          {
            type: 'receiveDismissVulnerabilityError',
            payload: 'There was an error dismissing the vulnerability. Please try again.',
          },
        ],
        done,
      );
    });
  });

  describe('addDismissalComment', () => {
    const vulnerability = {
      id: 0,
      vulnerability_feedback_dismissal_path: 'foo',
      dismissalFeedback: { id: 1 },
    };
    const data = { vulnerability };
    const url = `${state.createVulnerabilityFeedbackDismissalPath}/${vulnerability.dismissalFeedback.id}`;
    const comment = 'Well, we’re back in the car again.';

    describe('on success', () => {
      beforeEach(() => {
        mock.onPatch(url).replyOnce(200, data);
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          addDismissalComment,
          { comment },
          { modal: { vulnerability } },
          [],
          [
            { type: 'requestAddDismissalComment' },
            { type: 'closeDismissalCommentBox' },
            {
              type: 'receiveAddDismissalCommentSuccess',
              payload: { data },
            },
          ],
          done,
        );
      });

      it('should show added dismissal comment toast message', done => {
        spyOn(Vue.toasted, 'show').and.callThrough();

        const checkToastMessage = () => {
          expect(Vue.toasted.show).toHaveBeenCalledTimes(1);
          done();
        };

        testAction(
          addDismissalComment,
          { comment },
          { modal: { vulnerability } },
          [],
          [
            { type: 'requestAddDismissalComment' },
            { type: 'closeDismissalCommentBox' },
            {
              type: 'receiveAddDismissalCommentSuccess',
              payload: { data },
            },
          ],
          checkToastMessage,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onPatch(url).replyOnce(404);
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          addDismissalComment,
          { comment },
          { modal: { vulnerability } },
          [],
          [
            { type: 'requestAddDismissalComment' },
            {
              type: 'receiveAddDismissalCommentError',
              payload: 'There was an error adding the comment.',
            },
          ],
          done,
        );
      });
    });

    describe('receiveAddDismissalCommentSuccess', () => {
      it('should commit the success mutation', done => {
        testAction(
          receiveAddDismissalCommentSuccess,
          { data },
          state,
          [{ type: types.RECEIVE_ADD_DISMISSAL_COMMENT_SUCCESS, payload: { data } }],
          [],
          done,
        );
      });
    });

    describe('receiveAddDismissalCommentError', () => {
      it('should commit the error mutation', done => {
        testAction(
          receiveAddDismissalCommentError,
          {},
          state,
          [
            {
              type: types.RECEIVE_ADD_DISMISSAL_COMMENT_ERROR,
              payload: {},
            },
          ],
          [],
          done,
        );
      });
    });

    describe('requestAddDismissalComment', () => {
      it('should commit the request mutation', done => {
        testAction(
          requestAddDismissalComment,
          {},
          state,
          [{ type: types.REQUEST_ADD_DISMISSAL_COMMENT }],
          [],
          done,
        );
      });
    });
  });

  describe('deleteDismissalComment', () => {
    const vulnerability = {
      id: 0,
      vulnerability_feedback_dismissal_path: 'foo',
      dismissalFeedback: { id: 1 },
    };
    const data = { vulnerability };
    const url = `${state.createVulnerabilityFeedbackDismissalPath}/${vulnerability.dismissalFeedback.id}`;
    const comment = '';

    describe('on success', () => {
      beforeEach(() => {
        mock.onPatch(url).replyOnce(200, data);
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          deleteDismissalComment,
          { comment },
          { modal: { vulnerability } },
          [],
          [
            { type: 'requestDeleteDismissalComment' },
            { type: 'closeDismissalCommentBox' },
            {
              type: 'receiveDeleteDismissalCommentSuccess',
              payload: { data },
            },
          ],
          done,
        );
      });

      it('should show deleted dismissal comment toast message', done => {
        spyOn(Vue.toasted, 'show').and.callThrough();

        const checkToastMessage = () => {
          expect(Vue.toasted.show).toHaveBeenCalledTimes(1);
          done();
        };

        testAction(
          deleteDismissalComment,
          { comment },
          { modal: { vulnerability } },
          [],
          [
            { type: 'requestDeleteDismissalComment' },
            { type: 'closeDismissalCommentBox' },
            {
              type: 'receiveDeleteDismissalCommentSuccess',
              payload: { data },
            },
          ],
          checkToastMessage,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onPatch(url).replyOnce(404);
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          deleteDismissalComment,
          { comment },
          { modal: { vulnerability } },
          [],
          [
            { type: 'requestDeleteDismissalComment' },
            {
              type: 'receiveDeleteDismissalCommentError',
              payload: 'There was an error deleting the comment.',
            },
          ],
          done,
        );
      });
    });

    describe('receiveDeleteDismissalCommentSuccess', () => {
      it('should commit the success mutation', done => {
        testAction(
          receiveDeleteDismissalCommentSuccess,
          { data },
          state,
          [{ type: types.RECEIVE_DELETE_DISMISSAL_COMMENT_SUCCESS, payload: { data } }],
          [],
          done,
        );
      });
    });

    describe('receiveDeleteDismissalCommentError', () => {
      it('should commit the error mutation', done => {
        testAction(
          receiveDeleteDismissalCommentError,
          {},
          state,
          [
            {
              type: types.RECEIVE_DELETE_DISMISSAL_COMMENT_ERROR,
              payload: {},
            },
          ],
          [],
          done,
        );
      });
    });

    describe('requestDeleteDismissalComment', () => {
      it('should commit the request mutation', done => {
        testAction(
          requestDeleteDismissalComment,
          {},
          state,
          [{ type: types.REQUEST_DELETE_DISMISSAL_COMMENT }],
          [],
          done,
        );
      });
    });
  });

  describe('showDismissalDeleteButtons', () => {
    it('commits show dismissal delete buttons', done => {
      testAction(
        showDismissalDeleteButtons,
        null,
        mockedState,
        [
          {
            type: types.SHOW_DISMISSAL_DELETE_BUTTONS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('hideDismissalDeleteButtons', () => {
    it('commits hide dismissal delete buttons', done => {
      testAction(
        hideDismissalDeleteButtons,
        null,
        mockedState,
        [
          {
            type: types.HIDE_DISMISSAL_DELETE_BUTTONS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('revertDismissVulnerability', () => {
    describe('with success', () => {
      let payload;

      beforeEach(() => {
        mock.onDelete('dismiss_vulnerability_path/123').reply(200, {});
        mockedState.modal.vulnerability.dismissalFeedback = {
          id: 123,
          destroy_vulnerability_feedback_dismissal_path: 'dismiss_vulnerability_path/123',
        };
        payload = createNonDismissedVulnerability({ ...mockedState.modal.vulnerability });
      });

      it('should dispatch `receiveDismissVulnerability`', done => {
        testAction(
          revertDismissVulnerability,
          payload,
          mockedState,
          [],
          [
            {
              type: 'requestDismissVulnerability',
            },
            {
              type: 'receiveDismissVulnerability',
              payload,
            },
          ],
          done,
        );
      });
    });

    it('with error should dispatch `receiveDismissVulnerabilityError`', done => {
      mock.onDelete('dismiss_vulnerability_path/123').reply(500, {});
      mockedState.modal.vulnerability.dismissalFeedback = { id: 123 };
      mockedState.createVulnerabilityFeedbackDismissalPath = 'dismiss_vulnerability_path';

      testAction(
        revertDismissVulnerability,
        null,
        mockedState,
        [],
        [
          {
            type: 'requestDismissVulnerability',
          },
          {
            type: 'receiveDismissVulnerabilityError',
            payload: 'There was an error reverting the dismissal. Please try again.',
          },
        ],
        done,
      );
    });
  });

  describe('requestCreateIssue', () => {
    it('commits request create issue', done => {
      testAction(
        requestCreateIssue,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_CREATE_ISSUE,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveCreateIssue', () => {
    it('commits receive create issue', done => {
      testAction(
        receiveCreateIssue,
        null,
        mockedState,
        [
          {
            type: types.RECEIVE_CREATE_ISSUE_SUCCESS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveCreateIssueError', () => {
    it('commits receive create issue error with payload', done => {
      testAction(
        receiveCreateIssueError,
        'error',
        mockedState,
        [
          {
            type: types.RECEIVE_CREATE_ISSUE_ERROR,
            payload: 'error',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('createNewIssue', () => {
    beforeEach(() => {
      spyOnDependency(actions, 'visitUrl');
    });

    it('with success should dispatch `requestCreateIssue` and `receiveCreateIssue`', done => {
      mock.onPost('create_issue_path').reply(200, { issue_path: 'new_issue' });
      mockedState.createVulnerabilityFeedbackIssuePath = 'create_issue_path';

      testAction(
        createNewIssue,
        null,
        mockedState,
        [],
        [
          {
            type: 'requestCreateIssue',
          },
          {
            type: 'receiveCreateIssue',
          },
        ],
        done,
      );
    });

    it('with error should dispatch `receiveCreateIssueError`', done => {
      mock.onPost('create_issue_path').reply(500, {});
      mockedState.vulnerabilityFeedbackPath = 'create_issue_path';

      testAction(
        createNewIssue,
        null,
        mockedState,
        [],
        [
          {
            type: 'requestCreateIssue',
          },
          {
            type: 'receiveCreateIssueError',
            payload: 'There was an error creating the issue. Please try again.',
          },
        ],
        done,
      );
    });
  });

  describe('downloadPatch', () => {
    it('creates a download link and clicks on it to download the file', () => {
      spyOn(document, 'createElement').and.callThrough();
      spyOn(document.body, 'appendChild').and.callThrough();
      spyOn(document.body, 'removeChild').and.callThrough();

      downloadPatch({
        state: {
          modal: {
            vulnerability: {
              remediations: [
                {
                  diff: 'abcdef',
                },
              ],
            },
          },
        },
      });

      expect(document.createElement).toHaveBeenCalledTimes(1);
      expect(document.body.appendChild).toHaveBeenCalledTimes(1);
      expect(document.body.removeChild).toHaveBeenCalledTimes(1);
    });
  });

  describe('requestCreateMergeRequest', () => {
    it('commits request create merge request', done => {
      testAction(
        requestCreateMergeRequest,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_CREATE_MERGE_REQUEST,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveCreateMergeRequestSuccess', () => {
    it('commits receive create merge request', done => {
      const data = { foo: 'bar' };

      testAction(
        receiveCreateMergeRequestSuccess,
        data,
        mockedState,
        [
          {
            type: types.RECEIVE_CREATE_MERGE_REQUEST_SUCCESS,
            payload: data,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveCreateMergeRequestError', () => {
    it('commits receive create merge request error', done => {
      testAction(
        receiveCreateMergeRequestError,
        '',
        mockedState,
        [
          {
            type: types.RECEIVE_CREATE_MERGE_REQUEST_ERROR,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('createMergeRequest', () => {
    beforeEach(() => {
      spyOnDependency(actions, 'visitUrl');
    });

    it('with success should dispatch `receiveCreateMergeRequestSuccess`', done => {
      const data = { merge_request_path: 'fakepath.html' };
      mockedState.createVulnerabilityFeedbackMergeRequestPath = 'create_merge_request_path';
      mock.onPost('create_merge_request_path').reply(200, data);

      testAction(
        createMergeRequest,
        null,
        mockedState,
        [],
        [
          {
            type: 'requestCreateMergeRequest',
          },
          {
            type: 'receiveCreateMergeRequestSuccess',
            payload: data,
          },
        ],
        done,
      );
    });

    it('with error should dispatch `receiveCreateMergeRequestError`', done => {
      mock.onPost('create_merge_request_path').reply(500, {});
      mockedState.vulnerabilityFeedbackPath = 'create_merge_request_path';

      testAction(
        createMergeRequest,
        null,
        mockedState,
        [],
        [
          {
            type: 'requestCreateMergeRequest',
          },
          {
            type: 'receiveCreateMergeRequestError',
            payload: 'There was an error creating the merge request. Please try again.',
          },
        ],
        done,
      );
    });
  });

  describe('updateDependencyScanningIssue', () => {
    it('commits update dependency scanning issue', done => {
      const payload = { foo: 'bar' };

      testAction(
        updateDependencyScanningIssue,
        payload,
        mockedState,
        [
          {
            type: types.UPDATE_DEPENDENCY_SCANNING_ISSUE,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('updateContainerScanningIssue', () => {
    it('commits update container scanning issue', done => {
      const payload = { foo: 'bar' };

      testAction(
        updateContainerScanningIssue,
        payload,
        mockedState,
        [
          {
            type: types.UPDATE_CONTAINER_SCANNING_ISSUE,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('updateDastIssue', () => {
    it('commits update dast issue', done => {
      const payload = { foo: 'bar' };

      testAction(
        updateDastIssue,
        payload,
        mockedState,
        [
          {
            type: types.UPDATE_DAST_ISSUE,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setSastContainerDiffEndpoint', () => {
    it('should pass down the endpoint to the mutation', done => {
      const payload = '/sast_container_endpoint.json';

      testAction(
        setSastContainerDiffEndpoint,
        payload,
        mockedState,
        [
          {
            type: types.SET_SAST_CONTAINER_DIFF_ENDPOINT,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveSastContainerDiffSuccess', () => {
    it('should pass down the response to the mutation', done => {
      const payload = { data: 'Effort yields its own rewards.' };

      testAction(
        receiveSastContainerDiffSuccess,
        payload,
        mockedState,
        [
          {
            type: types.RECEIVE_SAST_CONTAINER_DIFF_SUCCESS,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveSastContainerDiffError', () => {
    it('should commit container diff error mutation', done => {
      testAction(
        receiveSastContainerDiffError,
        undefined,
        mockedState,
        [
          {
            type: types.RECEIVE_SAST_CONTAINER_DIFF_ERROR,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchSastContainerDiff', () => {
    const diff = { vulnerabilities: [] };

    beforeEach(() => {
      mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_feedback';
      mockedState.sastContainer.paths.diffEndpoint = 'sast_container_diff.json';
    });

    describe('on success', () => {
      it('should dispatch `receiveSastContainerDiffSuccess`', done => {
        mock.onGet('sast_container_diff.json').reply(200, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'container_scanning',
            },
          })
          .reply(200, containerScanningFeedbacks);

        testAction(
          fetchSastContainerDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestSastContainerReports',
            },
            {
              type: 'receiveSastContainerDiffSuccess',
              payload: {
                diff,
                enrichData: containerScanningFeedbacks,
              },
            },
          ],
          done,
        );
      });
    });

    describe('when vulnerabilities path errors', () => {
      it('should dispatch `receiveSastContainerError`', done => {
        mock.onGet('sast_container_diff.json').reply(500);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'container_scanning',
            },
          })
          .reply(200, containerScanningFeedbacks);

        testAction(
          fetchSastContainerDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestSastContainerReports',
            },
            {
              type: 'receiveSastContainerDiffError',
            },
          ],
          done,
        );
      });
    });

    describe('when feedback path errors', () => {
      it('should dispatch `receiveSastContainerError`', done => {
        mock.onGet('sast_container_diff.json').reply(200, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'container_scanning',
            },
          })
          .reply(500);

        testAction(
          fetchSastContainerDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestSastContainerReports',
            },
            {
              type: 'receiveSastContainerDiffError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('setDependencyScanningDiffEndpoint', () => {
    it('should pass down the endpoint to the mutation', done => {
      const payload = '/dependency_scanning_endpoint.json';

      testAction(
        setDependencyScanningDiffEndpoint,
        payload,
        mockedState,
        [
          {
            type: types.SET_DEPENDENCY_SCANNING_DIFF_ENDPOINT,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDependencyScanningDiffSuccess', () => {
    it('should pass down the response to the mutation', done => {
      const payload = { data: 'Effort yields its own rewards.' };

      testAction(
        receiveDependencyScanningDiffSuccess,
        payload,
        mockedState,
        [
          {
            type: types.RECEIVE_DEPENDENCY_SCANNING_DIFF_SUCCESS,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDependencyScanningDiffError', () => {
    it('should commit dependency scanning diff error mutation', done => {
      testAction(
        receiveDependencyScanningDiffError,
        undefined,
        mockedState,
        [
          {
            type: types.RECEIVE_DEPENDENCY_SCANNING_DIFF_ERROR,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchDependencyScanningDiff', () => {
    const diff = { foo: {} };

    beforeEach(() => {
      mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_feedback';
      mockedState.dependencyScanning.paths.diffEndpoint = 'dependency_scanning_diff.json';
    });

    describe('on success', () => {
      it('should dispatch `receiveDependencyScanningDiffSuccess`', done => {
        mock.onGet('dependency_scanning_diff.json').reply(200, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'dependency_scanning',
            },
          })
          .reply(200, dependencyScanningFeedbacks);

        testAction(
          fetchDependencyScanningDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDependencyScanningReports',
            },
            {
              type: 'receiveDependencyScanningDiffSuccess',
              payload: {
                diff,
                enrichData: dependencyScanningFeedbacks,
              },
            },
          ],
          done,
        );
      });
    });

    describe('when vulnerabilities path errors', () => {
      it('should dispatch `receiveDependencyScanningError`', done => {
        mock.onGet('dependency_scanning_diff.json').reply(500);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'dependency_scanning',
            },
          })
          .reply(200, dependencyScanningFeedbacks);

        testAction(
          fetchDependencyScanningDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDependencyScanningReports',
            },
            {
              type: 'receiveDependencyScanningDiffError',
            },
          ],
          done,
        );
      });
    });

    describe('when feedback path errors', () => {
      it('should dispatch `receiveDependencyScanningError`', done => {
        mock.onGet('dependency_scanning_diff.json').reply(200, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'dependency_scanning',
            },
          })
          .reply(500);

        testAction(
          fetchDependencyScanningDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDependencyScanningReports',
            },
            {
              type: 'receiveDependencyScanningDiffError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('setDastDiffEndpoint', () => {
    it('should pass down the endpoint to the mutation', done => {
      const payload = '/dast_endpoint.json';

      testAction(
        setDastDiffEndpoint,
        payload,
        mockedState,
        [
          {
            type: types.SET_DAST_DIFF_ENDPOINT,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDastDiffSuccess', () => {
    it('should pass down the response to the mutation', done => {
      const payload = { data: 'Effort yields its own rewards.' };

      testAction(
        receiveDastDiffSuccess,
        payload,
        mockedState,
        [
          {
            type: types.RECEIVE_DAST_DIFF_SUCCESS,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDastDiffError', () => {
    it('should commit dast diff error mutation', done => {
      testAction(
        receiveDastDiffError,
        undefined,
        mockedState,
        [
          {
            type: types.RECEIVE_DAST_DIFF_ERROR,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchDastDiff', () => {
    const diff = { foo: {} };

    beforeEach(() => {
      mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_feedback';
      mockedState.dast.paths.diffEndpoint = 'dast_diff.json';
    });

    describe('on success', () => {
      it('should dispatch `receiveDastDiffSuccess`', done => {
        mock.onGet('dast_diff.json').reply(200, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'dast',
            },
          })
          .reply(200, dastFeedbacks);

        testAction(
          fetchDastDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDastReports',
            },
            {
              type: 'receiveDastDiffSuccess',
              payload: {
                diff,
                enrichData: dastFeedbacks,
              },
            },
          ],
          done,
        );
      });
    });

    describe('when vulnerabilities path errors', () => {
      it('should dispatch `receiveDastError`', done => {
        mock.onGet('dast_diff.json').reply(500);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'dast',
            },
          })
          .reply(200, dastFeedbacks);

        testAction(
          fetchDastDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDastReports',
            },
            {
              type: 'receiveDastDiffError',
            },
          ],
          done,
        );
      });
    });

    describe('when feedback path errors', () => {
      it('should dispatch `receiveDastError`', done => {
        mock.onGet('dast_diff.json').reply(200, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'dast',
            },
          })
          .reply(500);

        testAction(
          fetchDastDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDastReports',
            },
            {
              type: 'receiveDastDiffError',
            },
          ],
          done,
        );
      });
    });
  });
});
