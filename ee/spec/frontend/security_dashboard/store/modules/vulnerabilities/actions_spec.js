import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/security_dashboard/store/modules/vulnerabilities/actions';
import * as types from 'ee/security_dashboard/store/modules/vulnerabilities/mutation_types';
import initialState from 'ee/security_dashboard/store/modules/vulnerabilities/state';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';

import axios from '~/lib/utils/axios_utils';
import toast from '~/vue_shared/plugins/global_toast';

import mockDataVulnerabilities from './data/mock_data_vulnerabilities';

const sourceBranch = 'feature-branch-1';

jest.mock('~/vue_shared/plugins/global_toast');

jest.mock('jquery', () => () => ({
  modal: jest.fn(),
}));

describe('vulnerabilities count actions', () => {
  let state;

  beforeEach(() => {
    state = initialState();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('setPipelineId', () => {
    const pipelineId = 123;

    it('should commit the correct mutation', () => {
      return testAction(actions.setPipelineId, pipelineId, state, [
        {
          type: types.SET_PIPELINE_ID,
          payload: pipelineId,
        },
      ]);
    });
  });

  describe('setSourceBranch', () => {
    it('should commit the correct mutation', () => {
      return testAction(actions.setSourceBranch, sourceBranch, state, [
        {
          type: types.SET_SOURCE_BRANCH,
          payload: sourceBranch,
        },
      ]);
    });
  });
});

describe('vulnerabilities actions', () => {
  const data = mockDataVulnerabilities;
  const params = { filters: { severity: ['critical'] } };
  const filteredData = mockDataVulnerabilities.filter((vuln) => vuln.severity === 'critical');
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
  let state;

  beforeEach(() => {
    state = initialState();
  });

  describe('fetchVulnerabilities', () => {
    let mock;

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

      it('should dispatch the request and success actions', () => {
        return testAction(
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
        );
      });

      it('should pass through the filters', () => {
        return testAction(
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
        );
      });
    });

    describe('on error', () => {
      const errorCode = 404;

      beforeEach(() => {
        mock.onGet(state.vulnerabilitiesEndpoint).replyOnce(errorCode, {});
      });

      it('should dispatch the request and error actions', () => {
        return testAction(
          actions.fetchVulnerabilities,
          {},
          state,
          [],
          [
            { type: 'requestVulnerabilities' },
            { type: 'receiveVulnerabilitiesError', payload: errorCode },
          ],
        );
      });
    });

    describe('with an empty endpoint', () => {
      beforeEach(() => {
        state.vulnerabilitiesEndpoint = '';
      });

      it('should not do anything', () => {
        return testAction(actions.fetchVulnerabilities, {}, state);
      });
    });

    describe('pending request', () => {
      it('cancels the pending request when a new one is made', () => {
        const dispatch = jest.fn();
        const cancel = jest.fn();
        jest.spyOn(axios.CancelToken, 'source').mockImplementation(() => ({ cancel }));
        actions.fetchVulnerabilities({ state, dispatch });
        actions.fetchVulnerabilities({ state, dispatch });

        expect(cancel).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('receiveVulnerabilitiesSuccess', () => {
    it('should commit the success mutation', () => {
      return testAction(actions.receiveVulnerabilitiesSuccess, { headers, data }, state, [
        {
          type: types.RECEIVE_VULNERABILITIES_SUCCESS,
          payload: { pageInfo, vulnerabilities: data },
        },
      ]);
    });

    it('should transform each details property to camelCase', () => {
      const dataWithDetails = [{ id: '1', details: { prop_one: '1' } }];

      return testAction(
        actions.receiveVulnerabilitiesSuccess,
        { headers, data: dataWithDetails },
        state,
        [
          {
            type: types.RECEIVE_VULNERABILITIES_SUCCESS,
            payload: { pageInfo, vulnerabilities: [{ id: '1', details: { propOne: '1' } }] },
          },
        ],
      );
    });
  });

  describe('receiveVulnerabilitiesError', () => {
    it('should commit the error mutation', () => {
      const errorCode = 403;

      return testAction(actions.receiveVulnerabilitiesError, errorCode, state, [
        { type: types.RECEIVE_VULNERABILITIES_ERROR, payload: errorCode },
      ]);
    });
  });

  describe('requestVulnerabilities', () => {
    it('should commit the request mutation', () => {
      return testAction(actions.requestVulnerabilities, {}, state, [
        { type: types.REQUEST_VULNERABILITIES },
      ]);
    });
  });

  describe('setVulnerabilitiesEndpoint', () => {
    it('should commit the correct mutuation', () => {
      const endpoint = 'fakepath.json';

      return testAction(actions.setVulnerabilitiesEndpoint, endpoint, state, [
        {
          type: types.SET_VULNERABILITIES_ENDPOINT,
          payload: endpoint,
        },
      ]);
    });
  });

  describe('setVulnerabilitiesPage', () => {
    it('should commit the correct mutuation', () => {
      const page = 3;

      return testAction(actions.setVulnerabilitiesPage, page, state, [
        {
          type: types.SET_VULNERABILITIES_PAGE,
          payload: page,
        },
      ]);
    });
  });
});

describe('setModalData', () => {
  let state;

  beforeEach(() => {
    state = initialState();
  });

  it('should commit the SET_MODAL_DATA mutation', () => {
    const vulnerability = mockDataVulnerabilities[0];

    return testAction(actions.setModalData, { vulnerability }, state, [
      {
        type: types.SET_MODAL_DATA,
        payload: { vulnerability },
      },
    ]);
  });
});

describe('downloadPatch', () => {
  it('creates a download link and clicks on it to download the file', () => {
    const a = { click: jest.fn() };
    jest.spyOn(document, 'createElement').mockImplementation(() => a);

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
    expect(document.createElement).toHaveBeenCalledWith('a');
    expect(a.click).toHaveBeenCalledTimes(1);
    expect(a.download).toBe('remediation.patch');
    expect(a.href).toContain('data:text/plain;base64');
  });
});

describe('issue creation', () => {
  let state;

  beforeEach(() => {
    state = initialState();
  });

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

      it('should dispatch the request and success actions', () => {
        return testAction(
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
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onPost(vulnerability.create_vulnerability_feedback_issue_path).replyOnce(404, {});
      });

      it('should dispatch the request and error actions', () => {
        const flashError = false;

        return testAction(
          actions.createIssue,
          { vulnerability, flashError },
          {},
          [],
          [
            { type: 'requestCreateIssue' },
            { type: 'receiveCreateIssueError', payload: { flashError } },
          ],
        );
      });
    });
  });

  describe('receiveCreateIssueSuccess', () => {
    it('should commit the success mutation', () => {
      const data = mockDataVulnerabilities[0];

      return testAction(actions.receiveCreateIssueSuccess, { data }, state, [
        {
          type: types.RECEIVE_CREATE_ISSUE_SUCCESS,
          payload: { data },
        },
      ]);
    });
  });

  describe('receiveCreateIssueError', () => {
    it('should commit the error mutation', () => {
      return testAction(actions.receiveCreateIssueError, {}, state, [
        { type: types.RECEIVE_CREATE_ISSUE_ERROR },
      ]);
    });
  });

  describe('requestCreateIssue', () => {
    it('should commit the request mutation', () => {
      return testAction(actions.requestCreateIssue, {}, state, [
        { type: types.REQUEST_CREATE_ISSUE },
      ]);
    });
  });
});

describe('merge request creation', () => {
  let state;

  beforeEach(() => {
    state = initialState();
  });

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

      it('should dispatch the request and success actions', () => {
        return testAction(
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
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onPost(vulnerability.vulnerability_feedback_merge_request_path).replyOnce(404, {});
      });

      it('should dispatch the request and error actions', () => {
        const flashError = false;

        return testAction(
          actions.createMergeRequest,
          { vulnerability, flashError },
          {},
          [],
          [
            { type: 'requestCreateMergeRequest' },
            { type: 'receiveCreateMergeRequestError', payload: { flashError } },
          ],
        );
      });
    });
  });

  describe('receiveCreateMergeRequestSuccess', () => {
    it('should commit the success mutation', () => {
      const data = mockDataVulnerabilities[0];

      return testAction(actions.receiveCreateMergeRequestSuccess, { data }, state, [
        {
          type: types.RECEIVE_CREATE_MERGE_REQUEST_SUCCESS,
          payload: { data },
        },
      ]);
    });
  });

  describe('receiveCreateMergeRequestError', () => {
    it('should commit the error mutation', () => {
      return testAction(actions.receiveCreateMergeRequestError, {}, state, [
        { type: types.RECEIVE_CREATE_MERGE_REQUEST_ERROR },
      ]);
    });
  });

  describe('requestCreateMergeRequest', () => {
    it('should commit the request mutation', () => {
      return testAction(actions.requestCreateMergeRequest, {}, state, [
        { type: types.REQUEST_CREATE_MERGE_REQUEST },
      ]);
    });
  });
});

describe('vulnerability dismissal', () => {
  let state;

  beforeEach(() => {
    state = initialState();
  });

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

      it('should dispatch the request and success actions', () => {
        return testAction(
          actions.dismissVulnerability,
          { vulnerability, comment },
          {},
          [],
          [
            { type: 'requestDismissVulnerability' },
            { type: 'closeDismissalCommentBox' },
            {
              type: 'receiveDismissVulnerabilitySuccess',
              payload: { data, vulnerability },
            },
          ],
        );
      });

      it('should show the dismissal toast message', () => {
        const checkToastMessage = () => {
          expect(toast).toHaveBeenCalledTimes(1);
        };

        return testAction(
          actions.dismissVulnerability,
          { vulnerability, comment },
          {},
          [],
          [
            { type: 'requestDismissVulnerability' },
            { type: 'closeDismissalCommentBox' },
            {
              type: 'receiveDismissVulnerabilitySuccess',
              payload: { data, vulnerability },
            },
          ],
          checkToastMessage,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onPost(vulnerability.create_vulnerability_feedback_dismissal_path).replyOnce(404, {});
      });

      it('should dispatch the request and error actions', () => {
        const flashError = false;

        return testAction(
          actions.dismissVulnerability,
          { vulnerability, flashError },
          {},
          [],
          [
            { type: 'requestDismissVulnerability' },
            { type: 'receiveDismissVulnerabilityError', payload: { flashError } },
          ],
        );
      });
    });

    describe('with dismissed vulnerabilities hidden', () => {
      beforeEach(() => {
        state = {
          ...initialState(),
          filters: {
            hideDismissed: true,
          },
        };
        mock
          .onPost(vulnerability.create_vulnerability_feedback_dismissal_path)
          .replyOnce(200, data);
      });

      it('should show the dismissal toast message and refresh vulnerabilities', () => {
        const checkToastMessage = () => {
          const [message, options] = toast.mock.calls[0];

          expect(toast).toHaveBeenCalledTimes(1);
          expect(message).toContain('Turn off the hide dismissed toggle to view');
          expect(Object.keys(options.action)).toHaveLength(2);
        };

        return testAction(
          actions.dismissVulnerability,
          { vulnerability, comment },
          state,
          [],
          [
            { type: 'requestDismissVulnerability' },
            { type: 'closeDismissalCommentBox' },
            {
              type: 'receiveDismissVulnerabilitySuccess',
              payload: { data, vulnerability },
            },
            { type: 'fetchVulnerabilities', payload: { page: 1 } },
          ],
          checkToastMessage,
        );
      });

      it('should load the previous page if there are no more vulnerabilities on the current one and page > 1', () => {
        state.vulnerabilities = [mockDataVulnerabilities[0]];
        state.pageInfo.page = 3;

        return testAction(
          actions.dismissVulnerability,
          { vulnerability, comment },
          state,
          [],
          [
            { type: 'requestDismissVulnerability' },
            { type: 'closeDismissalCommentBox' },
            {
              type: 'receiveDismissVulnerabilitySuccess',
              payload: { data, vulnerability },
            },
            { type: 'fetchVulnerabilities', payload: { page: 2 } },
          ],
        );
      });
    });
  });

  describe('receiveDismissVulnerabilitySuccess', () => {
    it('should commit the success mutation', () => {
      const data = mockDataVulnerabilities[0];

      return testAction(actions.receiveDismissVulnerabilitySuccess, { data }, state, [
        {
          type: types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS,
          payload: { data },
        },
      ]);
    });
  });

  describe('receiveDismissVulnerabilityError', () => {
    it('should commit the error mutation', () => {
      return testAction(actions.receiveDismissVulnerabilityError, {}, state, [
        { type: types.RECEIVE_DISMISS_VULNERABILITY_ERROR },
      ]);
    });
  });

  describe('requestDismissVulnerability', () => {
    it('should commit the request mutation', () => {
      return testAction(actions.requestDismissVulnerability, {}, state, [
        { type: types.REQUEST_DISMISS_VULNERABILITY },
      ]);
    });
  });
});

describe('add vulnerability dismissal comment', () => {
  let state;

  beforeEach(() => {
    state = initialState();
  });

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

      it('should dispatch the request and success actions', () => {
        const checkPassedData = () => {
          const { project_id, id } = vulnerability.dismissal_feedback;
          const expected = JSON.stringify({ project_id, id, comment });

          expect(mock.history.patch[0].data).toBe(expected);
          expect(toast).toHaveBeenCalledTimes(1);
        };

        return testAction(
          actions.addDismissalComment,
          { vulnerability, comment },
          {},
          [],
          [
            { type: 'requestAddDismissalComment' },
            { type: 'closeDismissalCommentBox' },
            { type: 'receiveAddDismissalCommentSuccess', payload: { data, vulnerability } },
          ],
          checkPassedData,
        );
      });

      it('should show the add dismissal toast message', () => {
        const checkPassedData = () => {
          const { project_id, id } = vulnerability.dismissal_feedback;
          const expected = JSON.stringify({ project_id, id, comment });

          expect(mock.history.patch[0].data).toBe(expected);
          expect(toast).toHaveBeenCalledTimes(1);
        };

        return testAction(
          actions.addDismissalComment,
          { vulnerability, comment },
          {},
          [],
          [
            { type: 'requestAddDismissalComment' },
            { type: 'closeDismissalCommentBox' },
            { type: 'receiveAddDismissalCommentSuccess', payload: { data, vulnerability } },
          ],
          checkPassedData,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onPatch(url).replyOnce(404);
      });

      it('should dispatch the request and error actions', () => {
        return testAction(
          actions.addDismissalComment,
          { vulnerability, comment },
          {},
          [],
          [{ type: 'requestAddDismissalComment' }, { type: 'receiveAddDismissalCommentError' }],
        );
      });
    });

    describe('receiveAddDismissalCommentSuccess', () => {
      it('should commit the success mutation', () => {
        return testAction(actions.receiveAddDismissalCommentSuccess, { data }, state, [
          { type: types.RECEIVE_ADD_DISMISSAL_COMMENT_SUCCESS, payload: { data } },
        ]);
      });
    });

    describe('receiveAddDismissalCommentError', () => {
      it('should commit the error mutation', () => {
        return testAction(actions.receiveAddDismissalCommentError, {}, state, [
          { type: types.RECEIVE_ADD_DISMISSAL_COMMENT_ERROR },
        ]);
      });
    });

    describe('requestAddDismissalComment', () => {
      it('should commit the request mutation', () => {
        return testAction(actions.requestAddDismissalComment, {}, state, [
          { type: types.REQUEST_ADD_DISMISSAL_COMMENT },
        ]);
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

      it('should dispatch the request and success actions', () => {
        const checkPassedData = () => {
          const { project_id } = vulnerability.dismissal_feedback;
          const expected = JSON.stringify({ project_id, comment });

          expect(mock.history.patch[0].data).toBe(expected);
        };

        return testAction(
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

      it('should show the delete dismissal comment toast message', () => {
        const checkPassedData = () => {
          const { project_id } = vulnerability.dismissal_feedback;
          const expected = JSON.stringify({ project_id, comment });

          expect(mock.history.patch[0].data).toBe(expected);
          expect(toast).toHaveBeenCalledTimes(1);
        };

        return testAction(
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

      it('should dispatch the request and error actions', () => {
        return testAction(
          actions.deleteDismissalComment,
          { vulnerability },
          {},
          [],
          [
            { type: 'requestDeleteDismissalComment' },
            { type: 'receiveDeleteDismissalCommentError' },
          ],
        );
      });
    });

    describe('receiveDeleteDismissalCommentSuccess', () => {
      it('should commit the success mutation', () => {
        return testAction(actions.receiveDeleteDismissalCommentSuccess, { data }, state, [
          { type: types.RECEIVE_DELETE_DISMISSAL_COMMENT_SUCCESS, payload: { data } },
        ]);
      });
    });

    describe('receiveDeleteDismissalCommentError', () => {
      it('should commit the error mutation', () => {
        return testAction(actions.receiveDeleteDismissalCommentError, {}, state, [
          { type: types.RECEIVE_DELETE_DISMISSAL_COMMENT_ERROR },
        ]);
      });
    });

    describe('requestDeleteDismissalComment', () => {
      it('should commit the request mutation', () => {
        return testAction(actions.requestDeleteDismissalComment, {}, state, [
          { type: types.REQUEST_DELETE_DISMISSAL_COMMENT },
        ]);
      });
    });
  });
});

describe('dismiss multiple vulnerabilities', () => {
  let state;
  let selectedVulnerabilities;

  beforeEach(() => {
    state = initialState();
    state.vulnerabilities = mockDataVulnerabilities;
    selectedVulnerabilities = {
      [state.vulnerabilities[0].id]: true,
      [state.vulnerabilities[1].id]: true,
    };
    state.selectedVulnerabilities = selectedVulnerabilities;
  });

  describe('dismissSelectedVulnerabilities', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    it('should fire the dismissSelected mutations when all is well', () => {
      mock
        .onPost(state.vulnerabilities[0].create_vulnerability_feedback_dismissal_path)
        .replyOnce(200)
        .onPost(state.vulnerabilities[1].create_vulnerability_feedback_dismissal_path)
        .replyOnce(200);

      return testAction(
        actions.dismissSelectedVulnerabilities,
        {},
        state,
        [],
        [
          { type: 'requestDismissSelectedVulnerabilities' },
          {
            type: 'receiveDismissSelectedVulnerabilitiesSuccess',
          },
        ],
        () => {
          expect(mock.history.post).toHaveLength(2);
          expect(mock.history.post[0].url).toEqual(
            state.vulnerabilities[0].create_vulnerability_feedback_dismissal_path,
          );
        },
      );
    });

    it('should trigger the error state when something goes wrong', () => {
      mock
        .onPost(state.vulnerabilities[0].create_vulnerability_feedback_dismissal_path)
        .replyOnce(200)
        .onPost(state.vulnerabilities[1].create_vulnerability_feedback_dismissal_path)
        .replyOnce(500);

      return testAction(
        actions.dismissSelectedVulnerabilities,
        {},
        state,
        [],
        [
          { type: 'requestDismissSelectedVulnerabilities' },
          { type: 'receiveDismissSelectedVulnerabilitiesError', payload: { flashError: true } },
        ],
      );
    });

    describe('receiveDismissSelectedVulnerabilitiesSuccess', () => {
      it(`should commit ${types.RECEIVE_DISMISS_SELECTED_VULNERABILITIES_SUCCESS}`, () => {
        return testAction(
          actions.receiveDismissSelectedVulnerabilitiesSuccess,
          { selectedVulnerabilities },
          state,
          [{ type: types.RECEIVE_DISMISS_SELECTED_VULNERABILITIES_SUCCESS }],
        );
      });
    });

    describe('receiveDismissSelectedVulnerabilitiesError', () => {
      it(`should commit ${types.RECEIVE_DISMISS_SELECTED_VULNERABILITIES_ERROR}`, () => {
        return testAction(actions.receiveDismissSelectedVulnerabilitiesError, {}, state, [
          { type: types.RECEIVE_DISMISS_SELECTED_VULNERABILITIES_ERROR },
        ]);
      });
    });
  });
});

describe('selecting vulnerabilities', () => {
  let state;

  beforeEach(() => {
    state = initialState();
  });

  describe('selectVulnerability', () => {
    it(`selectVulnerability should commit ${types.SELECT_VULNERABILITY}`, () => {
      const id = 1234;

      return testAction(actions.selectVulnerability, { id }, state, [
        { type: types.SELECT_VULNERABILITY, payload: id },
      ]);
    });
  });

  describe('deselectVulnerability', () => {
    it(`should commit ${types.DESELECT_VULNERABILITY}`, () => {
      const id = 1234;

      return testAction(actions.deselectVulnerability, { id }, state, [
        { type: types.DESELECT_VULNERABILITY, payload: id },
      ]);
    });
  });

  describe('selectAllVulnerabilities', () => {
    it(`should commit ${types.SELECT_ALL_VULNERABILITIES}`, () => {
      return testAction(actions.selectAllVulnerabilities, {}, state, [
        { type: types.SELECT_ALL_VULNERABILITIES },
      ]);
    });
  });

  describe('deselectAllVulnerabilities', () => {
    it(`should commit ${types.DESELECT_ALL_VULNERABILITIES}`, () => {
      return testAction(actions.deselectAllVulnerabilities, {}, state, [
        { type: types.DESELECT_ALL_VULNERABILITIES },
      ]);
    });
  });
});

describe('showDismissalDeleteButtons', () => {
  let state;

  beforeEach(() => {
    state = initialState();
  });

  it('commits show dismissal delete buttons', () => {
    return testAction(actions.showDismissalDeleteButtons, null, state, [
      {
        type: types.SHOW_DISMISSAL_DELETE_BUTTONS,
      },
    ]);
  });
});

describe('hideDismissalDeleteButtons', () => {
  let state;

  beforeEach(() => {
    state = initialState();
  });

  it('commits hide dismissal delete buttons', () => {
    return testAction(actions.hideDismissalDeleteButtons, null, state, [
      {
        type: types.HIDE_DISMISSAL_DELETE_BUTTONS,
      },
    ]);
  });
});

describe('revert vulnerability dismissal', () => {
  describe('revertDismissVulnerability', () => {
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

      it('should dispatch the request and success actions', () => {
        return testAction(
          actions.revertDismissVulnerability,
          { vulnerability },
          {},
          [],
          [
            { type: 'requestUndoDismiss' },
            { type: 'receiveUndoDismissSuccess', payload: { vulnerability } },
          ],
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onDelete(url).replyOnce(404, {});
      });

      it('should dispatch the request and error actions', () => {
        const flashError = false;

        return testAction(
          actions.revertDismissVulnerability,
          { vulnerability, flashError },
          {},
          [],
          [
            { type: 'requestUndoDismiss' },
            { type: 'receiveUndoDismissError', payload: { flashError } },
          ],
        );
      });
    });
  });

  describe('receiveUndoDismissSuccess', () => {
    it('should commit the success mutation', () => {
      const state = initialState;
      const data = mockDataVulnerabilities[0];

      return testAction(actions.receiveUndoDismissSuccess, { data }, state, [
        {
          type: types.RECEIVE_REVERT_DISMISSAL_SUCCESS,
          payload: { data },
        },
      ]);
    });
  });

  describe('receiveUndoDismissError', () => {
    it('should commit the error mutation', () => {
      const state = initialState;

      return testAction(actions.receiveUndoDismissError, {}, state, [
        { type: types.RECEIVE_REVERT_DISMISSAL_ERROR },
      ]);
    });
  });

  describe('requestUndoDismiss', () => {
    it('should commit the request mutation', () => {
      const state = initialState;

      return testAction(actions.requestUndoDismiss, {}, state, [
        { type: types.REQUEST_REVERT_DISMISSAL },
      ]);
    });
  });
});

describe('dismissal comment box', () => {
  it('should commit the open comment mutation with a default payload', () => {
    return testAction(actions.openDismissalCommentBox, undefined, undefined, [
      { type: types.OPEN_DISMISSAL_COMMENT_BOX },
    ]);
  });

  it('should commit the close comment mutation', () => {
    return testAction(actions.closeDismissalCommentBox, {}, undefined, [
      { type: types.CLOSE_DISMISSAL_COMMENT_BOX },
    ]);
  });
});
