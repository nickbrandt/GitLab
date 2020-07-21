/* eslint-disable global-require */
import { memoize } from 'lodash';

export const getProject = memoize(() => require('test_fixtures/api/projects/get.json'));
export const getBranch = memoize(() => require('test_fixtures/api/branches/get.json'));
export const getMergeRequests = memoize(() => require('test_fixtures/api/merge_requests/get.json'));
export const getRepositoryFiles = memoize(() => require('test_fixtures/projects_json/files.json'));
export const getPipelinesEmptyResponse = memoize(() =>
  require('test_fixtures/projects_json/pipelines_empty.json'),
);
export const getCommit = memoize(() => getBranch().commit);
