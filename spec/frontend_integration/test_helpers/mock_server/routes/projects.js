import { buildQuery } from 'test_helpers/utils/query';

export default server => {
  server.get('/api/v4/projects/:id', (schema, request) => {
    const { id } = request.params;

    const proj =
      schema.projects.findBy({ id }) || schema.projects.findBy({ path_with_namespace: id });

    return proj.attrs;
  });

  server.get('/api/v4/projects/:id/merge_requests', (schema, request) => {
    const result = schema.mergeRequests.where(
      buildQuery(request.queryParams, {
        source_project_id: 'project_id',
        source_branch: 'source_branch',
      }),
    );

    return result.models;
  });
};
