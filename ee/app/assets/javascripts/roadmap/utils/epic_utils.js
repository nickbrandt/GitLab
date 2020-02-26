import createGqClient, { fetchPolicies } from '~/lib/graphql';

export const gqClient = createGqClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
  },
);

/**
 * Returns array of epics extracted from GraphQL response
 * discarding the `edges`->`node` nesting
 *
 * @param {Object} group
 */
export const extractGroupEpics = edges =>
  edges.map(({ node, epicNode = node }) => ({
    ...epicNode,
    // We can get rid of below two lines
    // by updating `epic_item_details.vue`
    // once we move to GraphQL permanently.
    groupName: epicNode.group.name,
    groupFullName: epicNode.group.fullName,
  }));
