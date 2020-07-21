import { getPipelinesEmptyResponse } from 'test_helpers/fixtures';

// eslint-disable-next-line import/prefer-default-export
export default server => {
  server.get('*/commit/:id/pipelines', () => {
    return getPipelinesEmptyResponse();
  });

  server.get('/api/v4/projects/:id/runners', () => {
    return [];
  });
};
