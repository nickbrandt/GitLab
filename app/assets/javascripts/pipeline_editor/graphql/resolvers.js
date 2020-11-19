import Api from '~/api';
import ciLintResolvers from '~/ci_lint/graphql/resolvers';

const { Mutation } = ciLintResolvers;

export const resolvers = {
  Query: {
    blobContent(_, { projectPath, path, ref }) {
      return {
        __typename: 'BlobContent',
        rawData: Api.getRawFile(projectPath, path, { ref }).then(({ data }) => {
          return data;
        }),
      };
    },
  },
  Mutation: {
    ...Mutation, // lintCI
  },
};

export default resolvers;
