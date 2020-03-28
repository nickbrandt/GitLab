import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import createState from 'ee/security_dashboard/store/modules/unscanned_projects/state';
import * as actions from 'ee/security_dashboard/store/modules/vulnerabilities/actions';
import axios from '~/lib/utils/axios_utils';

describe('EE Vulnerabilities actions', () => {
  const mockEndpoint = 'mock-list-endpoint';
  const mockResponse = [{ key_foo: 'valueFoo' }];

  let mockAxios;
  let state;
  let vulnerability;

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    state = createState();
    vulnerability = {
      create_vulnerability_feedback_issue_path: mockEndpoint,
      report_type: 'issue',
      project_fingerprint: 'some-fingerprint',
    };
  });

  afterEach(() => {
    mockAxios.restore();
  });

  describe('createIssue', () => {
    it('calls the createIssue endpoint and receives a success response', done => {
      mockAxios.onPost(mockEndpoint).replyOnce(200, mockResponse);
      const spy = jest.spyOn(axios, 'post');

      return testAction(
        actions.createIssue,
        {
          vulnerability,
        },
        state,
        [],
        [
          { type: 'requestCreateIssue' },
          { type: 'receiveCreateIssueSuccess', payload: mockResponse },
        ],
        () => {
          expect(spy).toHaveBeenCalledWith(mockEndpoint, {
            vulnerability_feedback: {
              category: 'issue',
              feedback_type: 'issue',
              project_fingerprint: 'some-fingerprint',
              vulnerability_data: {
                category: 'issue',
                create_vulnerability_feedback_issue_path: mockEndpoint,
                project_fingerprint: 'some-fingerprint',
                report_type: 'issue',
              },
            },
          });
          done();
        },
      );
    });

    it('handles an API error by dispatching "receiveCreateIssueError"', done => {
      mockAxios.onPost(mockEndpoint).replyOnce(500);

      return testAction(
        actions.createIssue,
        {
          vulnerability,
        },
        state,
        [],
        [
          { type: 'requestCreateIssue' },
          { type: 'receiveCreateIssueError', payload: { flashError: undefined } },
        ],
        done,
      );
    });
  });
});
