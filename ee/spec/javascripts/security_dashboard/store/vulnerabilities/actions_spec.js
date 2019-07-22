import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import testAction from 'spec/helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';
import { DAYS } from 'ee/security_dashboard/store/modules/vulnerabilities/constants';

import initialState from 'ee/security_dashboard/store/modules/vulnerabilities/state';
import * as types from 'ee/security_dashboard/store/modules/vulnerabilities/mutation_types';
import * as actions from 'ee/security_dashboard/store/modules/vulnerabilities/actions';

import mockDataVulnerabilities from './data/mock_data_vulnerabilities.json';
import mockDataVulnerabilitiesCount from './data/mock_data_vulnerabilities_count.json';
import mockDataVulnerabilitiesHistory from './data/mock_data_vulnerabilities_history.json';

describe('vulnerabilities count actions', () => {
  const data = mockDataVulnerabilitiesCount;
  const params = { filters: { type: ['sast'] } };
  const filteredData = mockDataVulnerabilitiesCount.sast;

  describe('setVulnerabilitiesCountEndpoint', () => {
    it('should commit the correct mutuation', done => {
      const state = initialState;
      const endpoint = 'fakepath.json';

      testAction(
        actions.setVulnerabilitiesCountEndpoint,
        endpoint,
        state,
        [
          {
            type: types.SET_VULNERABILITIES_COUNT_ENDPOINT,
            payload: endpoint,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchVulnerabilitiesCount', () => {
    let mock;
    const state = initialState;

    beforeEach(() => {
      state.vulnerabilitiesCountEndpoint = `${TEST_HOST}/vulnerabilities_count.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onGet(state.vulnerabilitiesCountEndpoint, { params })
          .replyOnce(200, filteredData)
          .onGet(state.vulnerabilitiesCountEndpoint)
          .replyOnce(200, data);
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.fetchVulnerabilitiesCount,
          {},
          state,
          [],
          [
            { type: 'requestVulnerabilitiesCount' },
            {
              type: 'receiveVulnerabilitiesCountSuccess',
              payload: { data },
            },
          ],
          done,
        );
      });

      it('should send the passed filters to the endpoint', done => {
        testAction(
          actions.fetchVulnerabilitiesCount,
          params,
          state,
          [],
          [
            { type: 'requestVulnerabilitiesCount' },
            {
              type: 'receiveVulnerabilitiesCountSuccess',
              payload: { data: filteredData },
            },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onGet(state.vulnerabilitiesCountEndpoint).replyOnce(404, {});
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.fetchVulnerabilitiesCount,
          {},
          state,
          [],
          [{ type: 'requestVulnerabilitiesCount' }, { type: 'receiveVulnerabilitiesCountError' }],
          done,
        );
      });
    });
  });

  describe('requestVulnerabilitiesCount', () => {
    it('should commit the request mutation', done => {
      const state = initialState;

      testAction(
        actions.requestVulnerabilitiesCount,
        {},
        state,
        [{ type: types.REQUEST_VULNERABILITIES_COUNT }],
        [],
        done,
      );
    });
  });

  describe('receiveVulnerabilitiesCountSuccess', () => {
    it('should commit the success mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveVulnerabilitiesCountSuccess,
        { data },
        state,
        [{ type: types.RECEIVE_VULNERABILITIES_COUNT_SUCCESS, payload: data }],
        [],
        done,
      );
    });
  });

  describe('receiveVulnerabilitiesCountError', () => {
    it('should commit the error mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveVulnerabilitiesCountError,
        {},
        state,
        [{ type: types.RECEIVE_VULNERABILITIES_COUNT_ERROR }],
        [],
        done,
      );
    });
  });
});

describe('vulnerabilities actions', () => {
  const data = mockDataVulnerabilities;
  const params = { filters: { severity: ['critical'] } };
  const filteredData = mockDataVulnerabilities.filter(vuln => vuln.severity === 'critical');
  const pageInfo = {
    page: 1,
    nextPage: 2,
    previousPage: 1,
    perPage: 20,
    total: 100,
    totalPages: 5,
  };
  const headers = {
    'X-Next-Page': pageInfo.nextPage,
    'X-Page': pageInfo.page,
    'X-Per-Page': pageInfo.perPage,
    'X-Prev-Page': pageInfo.previousPage,
    'X-Total': pageInfo.total,
    'X-Total-Pages': pageInfo.totalPages,
  };

  describe('fetchVulnerabilities', () => {
    let mock;
    const state = initialState;

    beforeEach(() => {
      state.vulnerabilitiesEndpoint = `${TEST_HOST}/vulnerabilities.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onGet(state.vulnerabilitiesEndpoint, { params })
          .replyOnce(200, filteredData, headers)
          .onGet(state.vulnerabilitiesEndpoint)
          .replyOnce(200, data, headers);
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.fetchVulnerabilities,
          {},
          state,
          [],
          [
            { type: 'requestVulnerabilities' },
            {
              type: 'receiveVulnerabilitiesSuccess',
              payload: { data, headers },
            },
          ],
          done,
        );
      });

      it('should pass through the filters', done => {
        testAction(
          actions.fetchVulnerabilities,
          params,
          state,
          [],
          [
            { type: 'requestVulnerabilities' },
            {
              type: 'receiveVulnerabilitiesSuccess',
              payload: { data: filteredData, headers },
            },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onGet(state.vulnerabilitiesEndpoint).replyOnce(404, {});
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.fetchVulnerabilities,
          {},
          state,
          [],
          [{ type: 'requestVulnerabilities' }, { type: 'receiveVulnerabilitiesError' }],
          done,
        );
      });
    });
  });

  describe('receiveVulnerabilitiesSuccess', () => {
    it('should commit the success mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveVulnerabilitiesSuccess,
        { headers, data },
        state,
        [
          {
            type: types.RECEIVE_VULNERABILITIES_SUCCESS,
            payload: { pageInfo, vulnerabilities: data },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveVulnerabilitiesError', () => {
    it('should commit the error mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveVulnerabilitiesError,
        {},
        state,
        [{ type: types.RECEIVE_VULNERABILITIES_ERROR }],
        [],
        done,
      );
    });
  });

  describe('requestVulnerabilities', () => {
    it('should commit the request mutation', done => {
      const state = initialState;

      testAction(
        actions.requestVulnerabilities,
        {},
        state,
        [{ type: types.REQUEST_VULNERABILITIES }],
        [],
        done,
      );
    });
  });

  describe('setVulnerabilitiesEndpoint', () => {
    it('should commit the correct mutuation', done => {
      const state = initialState;
      const endpoint = 'fakepath.json';

      testAction(
        actions.setVulnerabilitiesEndpoint,
        endpoint,
        state,
        [
          {
            type: types.SET_VULNERABILITIES_ENDPOINT,
            payload: endpoint,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setVulnerabilitiesPage', () => {
    it('should commit the correct mutuation', done => {
      const state = initialState;
      const page = 3;

      testAction(
        actions.setVulnerabilitiesPage,
        page,
        state,
        [
          {
            type: types.SET_VULNERABILITIES_PAGE,
            payload: page,
          },
        ],
        [],
        done,
      );
    });
  });
});

describe('openModal', () => {
  it('should commit the SET_MODAL_DATA mutation', done => {
    const state = initialState;
    const vulnerability = mockDataVulnerabilities[0];

    testAction(
      actions.openModal,
      { vulnerability },
      state,
      [
        {
          type: types.SET_MODAL_DATA,
          payload: { vulnerability },
        },
      ],
      [],
      done,
    );
  });
});

describe('downloadPatch', () => {
  it('creates a download link and clicks on it to download the file', () => {
    spyOn(document, 'createElement').and.callThrough();
    spyOn(document.body, 'appendChild').and.callThrough();
    spyOn(document.body, 'removeChild').and.callThrough();

    actions.downloadPatch({
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

describe('issue creation', () => {
  describe('createIssue', () => {
    const vulnerability = mockDataVulnerabilities[0];
    const data = { issue_url: 'fakepath.html' };
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onPost(vulnerability.create_vulnerability_feedback_issue_path)
          .replyOnce(200, { data });
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.createIssue,
          { vulnerability },
          {},
          [],
          [
            { type: 'requestCreateIssue' },
            {
              type: 'receiveCreateIssueSuccess',
              payload: { data },
            },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onPost(vulnerability.create_vulnerability_feedback_issue_path).replyOnce(404, {});
      });

      it('should dispatch the request and error actions', done => {
        const flashError = false;

        testAction(
          actions.createIssue,
          { vulnerability, flashError },
          {},
          [],
          [
            { type: 'requestCreateIssue' },
            { type: 'receiveCreateIssueError', payload: { flashError } },
          ],
          done,
        );
      });
    });
  });

  describe('receiveCreateIssueSuccess', () => {
    it('should commit the success mutation', done => {
      const state = initialState;
      const data = mockDataVulnerabilities[0];

      testAction(
        actions.receiveCreateIssueSuccess,
        { data },
        state,
        [
          {
            type: types.RECEIVE_CREATE_ISSUE_SUCCESS,
            payload: { data },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveCreateIssueError', () => {
    it('should commit the error mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveCreateIssueError,
        {},
        state,
        [{ type: types.RECEIVE_CREATE_ISSUE_ERROR }],
        [],
        done,
      );
    });
  });

  describe('requestCreateIssue', () => {
    it('should commit the request mutation', done => {
      const state = initialState;

      testAction(
        actions.requestCreateIssue,
        {},
        state,
        [{ type: types.REQUEST_CREATE_ISSUE }],
        [],
        done,
      );
    });
  });
});

describe('merge request creation', () => {
  describe('createMergeRequest', () => {
    const vulnerability = mockDataVulnerabilities[0];
    const data = { merge_request_path: 'fakepath.html' };
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onPost(vulnerability.vulnerability_feedback_merge_request_path)
          .replyOnce(200, { data });
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.createMergeRequest,
          { vulnerability },
          {},
          [],
          [
            { type: 'requestCreateMergeRequest' },
            {
              type: 'receiveCreateMergeRequestSuccess',
              payload: { data },
            },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onPost(vulnerability.vulnerability_feedback_merge_request_path).replyOnce(404, {});
      });

      it('should dispatch the request and error actions', done => {
        const flashError = false;

        testAction(
          actions.createMergeRequest,
          { vulnerability, flashError },
          {},
          [],
          [
            { type: 'requestCreateMergeRequest' },
            { type: 'receiveCreateMergeRequestError', payload: { flashError } },
          ],
          done,
        );
      });
    });
  });

  describe('receiveCreateMergeRequestSuccess', () => {
    it('should commit the success mutation', done => {
      const state = initialState;
      const data = mockDataVulnerabilities[0];

      testAction(
        actions.receiveCreateMergeRequestSuccess,
        { data },
        state,
        [
          {
            type: types.RECEIVE_CREATE_MERGE_REQUEST_SUCCESS,
            payload: { data },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveCreateMergeRequestError', () => {
    it('should commit the error mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveCreateMergeRequestError,
        {},
        state,
        [{ type: types.RECEIVE_CREATE_MERGE_REQUEST_ERROR }],
        [],
        done,
      );
    });
  });

  describe('requestCreateMergeRequest', () => {
    it('should commit the request mutation', done => {
      const state = initialState;

      testAction(
        actions.requestCreateMergeRequest,
        {},
        state,
        [{ type: types.REQUEST_CREATE_MERGE_REQUEST }],
        [],
        done,
      );
    });
  });
});

describe('vulnerability dismissal', () => {
  describe('dismissVulnerability', () => {
    const vulnerability = mockDataVulnerabilities[0];
    const data = { vulnerability };
    const comment =
      'How many times have I told you we need locking mechanisms on the vehicle doors!';
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onPost(vulnerability.create_vulnerability_feedback_dismissal_path)
          .replyOnce(200, data);
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.dismissVulnerability,
          { vulnerability, comment },
          {},
          [],
          [
            { type: 'requestDismissVulnerability' },
            { type: 'closeDismissalCommentBox' },
            {
              type: 'receiveDismissVulnerabilitySuccess',
              payload: { data, id: vulnerability.id },
            },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onPost(vulnerability.create_vulnerability_feedback_dismissal_path).replyOnce(404, {});
      });

      it('should dispatch the request and error actions', done => {
        const flashError = false;

        testAction(
          actions.dismissVulnerability,
          { vulnerability, flashError },
          {},
          [],
          [
            { type: 'requestDismissVulnerability' },
            { type: 'receiveDismissVulnerabilityError', payload: { flashError } },
          ],
          done,
        );
      });
    });
  });

  describe('receiveDismissVulnerabilitySuccess', () => {
    it('should commit the success mutation', done => {
      const state = initialState;
      const data = mockDataVulnerabilities[0];

      testAction(
        actions.receiveDismissVulnerabilitySuccess,
        { data },
        state,
        [
          {
            type: types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS,
            payload: { data },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDismissVulnerabilityError', () => {
    it('should commit the error mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveDismissVulnerabilityError,
        {},
        state,
        [{ type: types.RECEIVE_DISMISS_VULNERABILITY_ERROR }],
        [],
        done,
      );
    });
  });

  describe('requestDismissVulnerability', () => {
    it('should commit the request mutation', done => {
      const state = initialState;

      testAction(
        actions.requestDismissVulnerability,
        {},
        state,
        [{ type: types.REQUEST_DISMISS_VULNERABILITY }],
        [],
        done,
      );
    });
  });
});

describe('add vulnerability dismissal comment', () => {
  describe('addDismissalComment', () => {
    const vulnerability = mockDataVulnerabilities[2];
    const data = { vulnerability };
    const url = `${vulnerability.create_vulnerability_feedback_dismissal_path}/${vulnerability.dismissal_feedback.id}`;
    const comment = 'Well, we’re back in the car again.';
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock.onPatch(url).replyOnce(200, data);
      });

      it('should dispatch the request and success actions', done => {
        const checkPassedData = () => {
          const { project_id, id } = vulnerability.dismissal_feedback;
          const expected = { project_id, id, comment };

          expect(mock.history.patch[0].data).toBe(JSON.stringify(expected));
          done();
        };

        testAction(
          actions.addDismissalComment,
          { vulnerability, comment },
          {},
          [],
          [
            { type: 'requestAddDismissalComment' },
            { type: 'closeDismissalCommentBox' },
            { type: 'receiveAddDismissalCommentSuccess', payload: { data, id: vulnerability.id } },
          ],
          checkPassedData,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onPatch(url).replyOnce(404);
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.addDismissalComment,
          { vulnerability, comment },
          {},
          [],
          [{ type: 'requestAddDismissalComment' }, { type: 'receiveAddDismissalCommentError' }],
          done,
        );
      });
    });

    describe('receiveAddDismissalCommentSuccess', () => {
      it('should commit the success mutation', done => {
        const state = initialState;

        testAction(
          actions.receiveAddDismissalCommentSuccess,
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
        const state = initialState;

        testAction(
          actions.receiveAddDismissalCommentError,
          {},
          state,
          [{ type: types.RECEIVE_ADD_DISMISSAL_COMMENT_ERROR }],
          [],
          done,
        );
      });
    });

    describe('requestAddDismissalComment', () => {
      it('should commit the request mutation', done => {
        const state = initialState;

        testAction(
          actions.requestAddDismissalComment,
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
    const vulnerability = mockDataVulnerabilities[2];
    const data = { vulnerability };
    const url = `${vulnerability.create_vulnerability_feedback_dismissal_path}/${vulnerability.dismissal_feedback.id}`;
    const comment = '';
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock.onPatch(url).replyOnce(200, data);
      });

      it('should dispatch the request and success actions', done => {
        const checkPassedData = () => {
          const { project_id } = vulnerability.dismissal_feedback;
          const expected = { project_id, comment };

          expect(mock.history.patch[0].data).toBe(JSON.stringify(expected));
          done();
        };

        testAction(
          actions.deleteDismissalComment,
          { vulnerability },
          {},
          [],
          [
            { type: 'requestDeleteDismissalComment' },
            { type: 'closeDismissalCommentBox' },
            {
              type: 'receiveDeleteDismissalCommentSuccess',
              payload: { data, id: vulnerability.id },
            },
          ],
          checkPassedData,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onPatch(url).replyOnce(404);
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.deleteDismissalComment,
          { vulnerability },
          {},
          [],
          [
            { type: 'requestDeleteDismissalComment' },
            { type: 'receiveDeleteDismissalCommentError' },
          ],
          done,
        );
      });
    });

    describe('receiveDeleteDismissalCommentSuccess', () => {
      it('should commit the success mutation', done => {
        const state = initialState;

        testAction(
          actions.receiveDeleteDismissalCommentSuccess,
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
        const state = initialState;

        testAction(
          actions.receiveDeleteDismissalCommentError,
          {},
          state,
          [{ type: types.RECEIVE_DELETE_DISMISSAL_COMMENT_ERROR }],
          [],
          done,
        );
      });
    });

    describe('requestDeleteDismissalComment', () => {
      it('should commit the request mutation', done => {
        const state = initialState;

        testAction(
          actions.requestDeleteDismissalComment,
          {},
          state,
          [{ type: types.REQUEST_DELETE_DISMISSAL_COMMENT }],
          [],
          done,
        );
      });
    });
  });
});

describe('showDismissalDeleteButtons', () => {
  it('commits show dismissal delete buttons', done => {
    const state = initialState;

    testAction(
      actions.showDismissalDeleteButtons,
      null,
      state,
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
    const state = initialState;

    testAction(
      actions.hideDismissalDeleteButtons,
      null,
      state,
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

describe('revert vulnerability dismissal', () => {
  describe('undoDismiss', () => {
    const vulnerability = mockDataVulnerabilities[2];
    const url = vulnerability.dismissal_feedback.destroy_vulnerability_feedback_dismissal_path;
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock.onDelete(url).replyOnce(200, {});
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.undoDismiss,
          { vulnerability },
          {},
          [],
          [
            { type: 'requestUndoDismiss' },
            { type: 'receiveUndoDismissSuccess', payload: { id: vulnerability.id } },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onDelete(url).replyOnce(404, {});
      });

      it('should dispatch the request and error actions', done => {
        const flashError = false;

        testAction(
          actions.undoDismiss,
          { vulnerability, flashError },
          {},
          [],
          [
            { type: 'requestUndoDismiss' },
            { type: 'receiveUndoDismissError', payload: { flashError } },
          ],
          done,
        );
      });
    });
  });

  describe('receiveUndoDismissSuccess', () => {
    it('should commit the success mutation', done => {
      const state = initialState;
      const data = mockDataVulnerabilities[0];

      testAction(
        actions.receiveUndoDismissSuccess,
        { data },
        state,
        [
          {
            type: types.RECEIVE_REVERT_DISMISSAL_SUCCESS,
            payload: { data },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveUndoDismissError', () => {
    it('should commit the error mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveUndoDismissError,
        {},
        state,
        [{ type: types.RECEIVE_REVERT_DISMISSAL_ERROR }],
        [],
        done,
      );
    });
  });

  describe('requestUndoDismiss', () => {
    it('should commit the request mutation', done => {
      const state = initialState;

      testAction(
        actions.requestUndoDismiss,
        {},
        state,
        [{ type: types.REQUEST_REVERT_DISMISSAL }],
        [],
        done,
      );
    });
  });
});

describe('vulnerabilities history actions', () => {
  const data = mockDataVulnerabilitiesHistory;
  const params = { filters: { severity: ['critical'] } };
  const filteredData = mockDataVulnerabilitiesHistory.critical;

  describe('setVulnerabilitiesHistoryEndpoint', () => {
    it('should commit the correct mutuation', done => {
      const state = initialState;
      const endpoint = 'fakepath.json';

      testAction(
        actions.setVulnerabilitiesHistoryEndpoint,
        endpoint,
        state,
        [
          {
            type: types.SET_VULNERABILITIES_HISTORY_ENDPOINT,
            payload: endpoint,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setVulnerabilitiesHistoryDayRange', () => {
    it('should commit the number of past days to show', done => {
      const state = initialState;
      const days = DAYS.THIRTY;
      testAction(
        actions.setVulnerabilitiesHistoryDayRange,
        days,
        state,
        [
          {
            type: types.SET_VULNERABILITIES_HISTORY_DAY_RANGE,
            payload: days,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchVulnerabilitiesTimeline', () => {
    let mock;
    const state = initialState;

    beforeEach(() => {
      state.vulnerabilitiesHistoryEndpoint = `${TEST_HOST}/vulnerabilitIES_HISTORY.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onGet(state.vulnerabilitiesHistoryEndpoint, { params })
          .replyOnce(200, filteredData)
          .onGet(state.vulnerabilitiesHistoryEndpoint)
          .replyOnce(200, data);
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.fetchVulnerabilitiesHistory,
          {},
          state,
          [],
          [
            { type: 'requestVulnerabilitiesHistory' },
            {
              type: 'receiveVulnerabilitiesHistorySuccess',
              payload: { data },
            },
          ],
          done,
        );
      });

      it('return the filtered results', done => {
        testAction(
          actions.fetchVulnerabilitiesHistory,
          params,
          state,
          [],
          [
            { type: 'requestVulnerabilitiesHistory' },
            {
              type: 'receiveVulnerabilitiesHistorySuccess',
              payload: { data: filteredData },
            },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onGet(state.vulnerabilitiesHistoryEndpoint).replyOnce(404, {});
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.fetchVulnerabilitiesHistory,
          {},
          state,
          [],
          [
            { type: 'requestVulnerabilitiesHistory' },
            { type: 'receiveVulnerabilitiesHistoryError' },
          ],
          done,
        );
      });
    });
  });

  describe('requestVulnerabilitiesTimeline', () => {
    it('should commit the request mutation', done => {
      const state = initialState;

      testAction(
        actions.requestVulnerabilitiesHistory,
        {},
        state,
        [{ type: types.REQUEST_VULNERABILITIES_HISTORY }],
        [],
        done,
      );
    });
  });

  describe('receiveVulnerabilitiesTimelineSuccess', () => {
    it('should commit the success mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveVulnerabilitiesHistorySuccess,
        { data },
        state,
        [{ type: types.RECEIVE_VULNERABILITIES_HISTORY_SUCCESS, payload: data }],
        [],
        done,
      );
    });
  });

  describe('receiveVulnerabilitiesTimelineError', () => {
    it('should commit the error mutation', done => {
      const state = initialState;

      testAction(
        actions.receiveVulnerabilitiesHistoryError,
        {},
        state,
        [{ type: types.RECEIVE_VULNERABILITIES_HISTORY_ERROR }],
        [],
        done,
      );
    });
  });

  describe('openDismissalCommentBox', () => {
    it('should commit the open comment mutation with a default payload', done => {
      const state = initialState();

      testAction(
        actions.openDismissalCommentBox,
        undefined,
        state,
        [{ type: types.OPEN_DISMISSAL_COMMENT_BOX }],
        [],
        done,
      );
    });
  });

  describe('closeDismissalCommentBox', () => {
    it('should commit the close comment mutation', done => {
      const state = initialState();

      testAction(
        actions.closeDismissalCommentBox,
        {},
        state,
        [{ type: types.CLOSE_DISMISSAL_COMMENT_BOX }],
        [],
        done,
      );
    });
  });
});
