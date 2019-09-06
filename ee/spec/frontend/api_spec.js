import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import Api from 'ee/api';

describe('Api', () => {
  const dummyApiVersion = 'v3000';
  const dummyUrlRoot = '/gitlab';
  const dummyGon = {
    api_version: dummyApiVersion,
    relative_url_root: dummyUrlRoot,
  };
  const mockEpics = [
    {
      id: 1,
      iid: 10,
      group_id: 2,
      title: 'foo',
    },
    {
      id: 2,
      iid: 11,
      group_id: 2,
      title: 'bar',
    },
  ];

  let originalGon;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    originalGon = window.gon;
    window.gon = Object.assign({}, dummyGon);
  });

  afterEach(() => {
    mock.restore();
    window.gon = originalGon;
  });

  describe('ldapGroups', () => {
    it('calls callback on completion', done => {
      const query = 'query';
      const provider = 'provider';
      const callback = jasmine.createSpy();
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/ldap/${provider}/groups.json`;

      mock.onGet(expectedUrl).reply(200, [
        {
          name: 'test',
        },
      ]);

      Api.ldapGroups(query, provider, callback)
        .then(response => {
          expect(callback).toHaveBeenCalledWith(response);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('createChildEpic', () => {
    it('calls `axios.post` using params `groupId`, `parentEpicIid` and title', done => {
      const groupId = 'gitlab-org';
      const parentEpicIid = 1;
      const title = 'Sample epic';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/epics/${parentEpicIid}/epics`;
      const expectedRes = {
        title,
        id: 20,
        iid: 5,
      };

      mock.onPost(expectedUrl).reply(200, expectedRes);

      Api.createChildEpic({ groupId, parentEpicIid, title })
        .then(({ data }) => {
          expect(data.title).toBe(expectedRes.title);
          expect(data.id).toBe(expectedRes.id);
          expect(data.iid).toBe(expectedRes.iid);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('groupEpics', () => {
    it('calls `axios.get` using param `groupId`', done => {
      const groupId = 2;
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/epics?include_ancestor_groups=false&include_descendant_groups=true`;

      mock.onGet(expectedUrl).reply(200, mockEpics);

      Api.groupEpics({ groupId })
        .then(({ data }) => {
          data.forEach((epic, index) => {
            expect(epic.id).toBe(mockEpics[index].id);
            expect(epic.iid).toBe(mockEpics[index].iid);
            expect(epic.group_id).toBe(mockEpics[index].group_id);
            expect(epic.title).toBe(mockEpics[index].title);
          });
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('addEpicIssue', () => {
    it('calls `axios.post` using params `groupId`, `epicIid` and `issueId`', done => {
      const groupId = 2;
      const mockIssue = {
        id: 20,
      };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/epics/${mockEpics[0].iid}/issues/${mockIssue.id}`;
      const expectedRes = {
        id: 30,
        epic: mockEpics[0],
        issue: mockIssue,
      };

      mock.onPost(expectedUrl).reply(200, expectedRes);

      Api.addEpicIssue({ groupId, epicIid: mockEpics[0].iid, issueId: mockIssue.id })
        .then(({ data }) => {
          expect(data.id).toBe(expectedRes.id);
          expect(data.epic).toEqual(expect.objectContaining({ ...expectedRes.epic }));
          expect(data.issue).toEqual(expect.objectContaining({ ...expectedRes.issue }));
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('removeEpicIssue', () => {
    it('calls `axios.delete` using params `groupId`, `epicIid` and `epicIssueId`', done => {
      const groupId = 2;
      const mockIssue = {
        id: 20,
        epic_issue_id: 40,
      };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/epics/${mockEpics[0].iid}/issues/${mockIssue.epic_issue_id}`;
      const expectedRes = {
        id: 30,
        epic: mockEpics[0],
        issue: mockIssue,
      };

      mock.onDelete(expectedUrl).reply(200, expectedRes);

      Api.removeEpicIssue({
        groupId,
        epicIid: mockEpics[0].iid,
        epicIssueId: mockIssue.epic_issue_id,
      })
        .then(({ data }) => {
          expect(data.id).toBe(expectedRes.id);
          expect(data.epic).toEqual(expect.objectContaining({ ...expectedRes.epic }));
          expect(data.issue).toEqual(expect.objectContaining({ ...expectedRes.issue }));
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
