import { buildSchema, graphql } from 'graphql';
import gitlabSchemaStr from '../../../../doc/api/graphql/reference/gitlab_schema.graphql';

const graphqlSchema = buildSchema(gitlabSchemaStr.loc.source.body);
const graphqlResolvers = {
  project({ fullPath }, schema) {
    const result = schema.projects.findBy({ path_with_namespace: fullPath });

    return {
      ...result.attrs,
      userPermissions: {
        createMergeRequestIn: true,
        readMergeRequest: true,
        pushCode: true,
      },
    };
  },
};

// eslint-disable-next-line import/prefer-default-export
export const graphqlQuery = (query, variables, schema) =>
  graphql(graphqlSchema, query, graphqlResolvers, schema, variables);
