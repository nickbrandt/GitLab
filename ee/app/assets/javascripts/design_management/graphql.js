import Vue from 'vue';
import VueApollo from 'vue-apollo';
import _ from 'underscore';
import { defaultDataIdFromObject } from 'apollo-cache-inmemory';
import createDefaultClient from '~/lib/graphql';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import appDataQuery from './graphql/queries/appData.query.graphql';
import projectQuery from './graphql/queries/project.query.graphql';

const genericErrorMessage = s__(
  'DesignManagement|An error occurred while loading designs. Please try again.',
);

Vue.use(VueApollo);

const defaultClient = createDefaultClient(
  {
    Query: {
      design(ctx, { id, version }, { cache, client }) {
        const { projectPath, issueIid } = cache.readQuery({ query: appDataQuery });
        return client
          .query({
            query: projectQuery,
            variables: {
              fullPath: projectPath,
              iid: issueIid,
              atVersion: version,
            },
          })
          .then(({ data }) => {
            const edge = data.project.issue.designs.designs.edges.find(
              ({ node }) => node.filename === id,
            );
            return edge.node;
          })
          .catch(() => {
            createFlash(genericErrorMessage);
          });
      },
    },
  },
  // This config is added temporarily to resolve an issue with duplicate design IDs.
  // Should be removed as soon as https://gitlab.com/gitlab-org/gitlab/issues/13495 is resolved
  {
    cacheConfig: {
      dataIdFromObject: object => {
        // eslint-disable-next-line no-underscore-dangle, @gitlab/i18n/no-non-i18n-strings
        if (object.__typename === 'Design') {
          return object.id && object.image ? `${object.id}-${object.image}` : _.uniqueId();
        }
        return defaultDataIdFromObject(object);
      },
    },
  },
);

export default new VueApollo({
  defaultClient,
});
