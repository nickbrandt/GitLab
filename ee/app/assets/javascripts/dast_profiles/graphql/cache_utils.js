/**
 * Appends paginated results to existing ones
 * - to be used with $apollo.queries.x.fetchMore
 *
 * @param previousResult
 * @param fetchMoreResult
 * @returns {*}
 */
export const appendToPreviousResult = (previousResult, { fetchMoreResult }) => {
  const newResult = { ...fetchMoreResult };
  const previousEdges = previousResult.project.siteProfiles.edges;
  const newEdges = newResult.project.siteProfiles.edges;

  newResult.project.siteProfiles.edges = [...previousEdges, ...newEdges];

  return newResult;
};

/**
 * Removes profile with given id from the cache and writes the result to it
 *
 * @param store
 * @param queryBody
 * @param profileToBeDeletedId
 */
export const removeProfile = ({ store, queryBody, profileToBeDeletedId }) => {
  const data = store.readQuery(queryBody);

  data.project.siteProfiles.edges = data.project.siteProfiles.edges.filter(({ node }) => {
    return node.id !== profileToBeDeletedId;
  });

  store.writeQuery({ ...queryBody, data });
};

/**
 * Returns an object representing a optimistic response for site-profile deletion
 *
 * @returns {{__typename: string, dastSiteProfileDelete: {__typename: string, errors: []}}}
 */
export const dastSiteProfilesDeleteResponse = () => ({
  // eslint-disable-next-line @gitlab/require-i18n-strings
  __typename: 'Mutation',
  dastSiteProfileDelete: {
    __typename: 'DastSiteProfileDeletePayload',
    errors: [],
  },
});
