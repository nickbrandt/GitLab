import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import Api from 'ee/api';
import { TEST_HOST } from 'spec/test_constants';

const TEST_API_VERSION = 'v3000';
const TEST_PROJECT_ID = 17;
const TEST_RULE_ID = 22;

describe('EE Api', () => {
  let originalGon;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    originalGon = window.gon;
    window.gon = {
      api_version: TEST_API_VERSION,
      relative_url_root: TEST_HOST,
    };
  });

  afterEach(() => {
    mock.restore();
    window.gon = originalGon;
  });

  describe('getProjectApprovalRules', () => {
    it('gets with projectApprovalRulesPath', done => {
      const expectedData = { rules: [] };
      const expectedUrl = `${TEST_HOST}${Api.projectApprovalRulesPath}`
        .replace(':version', TEST_API_VERSION)
        .replace(':id', TEST_PROJECT_ID);

      mock.onGet(expectedUrl).reply(200, expectedData);
      Api.getProjectApprovalRules(TEST_PROJECT_ID)
        .then(response => {
          expect(response.data).toEqual(expectedData);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('postProjectApprovalRule', () => {
    it('posts with projectApprovalRulesPath', done => {
      const expectedUrl = `${TEST_HOST}${Api.projectApprovalRulesPath}`
        .replace(':version', TEST_API_VERSION)
        .replace(':id', TEST_PROJECT_ID);

      mock.onPost(expectedUrl).reply(200);
      Api.postProjectApprovalRule(TEST_PROJECT_ID)
        .then(done)
        .catch(done.fail);
    });
  });

  describe('putProjectApprovalRule', () => {
    it('puts with projectApprovalRulePath', done => {
      const rule = { name: 'Lorem' };
      const expectedUrl = `${TEST_HOST}${Api.projectApprovalRulePath}`
        .replace(':version', TEST_API_VERSION)
        .replace(':id', TEST_PROJECT_ID)
        .replace(':ruleid', TEST_RULE_ID);

      mock.onPut(expectedUrl).reply(200);
      Api.putProjectApprovalRule(TEST_PROJECT_ID, TEST_RULE_ID, rule)
        .then(() => {
          expect(mock.history.put.length).toBe(1);
          expect(mock.history.put[0].data).toBe(JSON.stringify(rule));
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('deleteProjectApprovalRule', () => {
    it('deletes with projectApprovalRulePath', done => {
      const expectedUrl = `${TEST_HOST}${Api.projectApprovalRulePath}`
        .replace(':version', TEST_API_VERSION)
        .replace(':id', TEST_PROJECT_ID)
        .replace(':ruleid', TEST_RULE_ID);

      mock.onDelete(expectedUrl).reply(200);
      Api.deleteProjectApprovalRule(TEST_PROJECT_ID, TEST_RULE_ID)
        .then(done)
        .catch(done.fail);
    });
  });
});
