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
});
