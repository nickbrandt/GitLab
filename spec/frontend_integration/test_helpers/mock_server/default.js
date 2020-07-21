/* eslint-disable global-require */
import { Server, Model, RestSerializer } from 'miragejs';
import { getProject, getBranch, getMergeRequests, getRepositoryFiles } from 'test_helpers/fixtures';
import setupRoutes from './routes';

export const createDefaultServerOptions = () => ({
  models: {
    project: Model,
    branch: Model,
    mergeRequest: Model,
    file: Model,
  },
  serializers: {
    application: RestSerializer.extend({
      root: false,
    }),
  },
  seeds(schema) {
    schema.db.loadData({
      files: getRepositoryFiles().map(path => ({ path })),
      projects: [getProject()],
      branches: [getBranch()],
      mergeRequests: getMergeRequests().map(mr => mr),
    });
  },
  routes() {
    this.namespace = '';
    this.urlPrefix = '/';

    setupRoutes(this);
  },
});

export const createDefaultServer = () => {
  const server = new Server(createDefaultServerOptions());
  return server;
};
