import createGqClient, { fetchPolicies } from '~/lib/graphql';

// eslint-disable-next-line import/prefer-default-export
export const gqClient = createGqClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
  },
);
