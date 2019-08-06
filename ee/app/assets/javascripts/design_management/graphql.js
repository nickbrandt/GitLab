import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import appDataQuery from './graphql/queries/appData.query.graphql';
import projectQuery from './graphql/queries/project.query.graphql';

Vue.use(VueApollo);

const defaultClient = createDefaultClient({
  Query: {
    design(ctx, { id }, { cache, client }) {
      const { projectPath, issueIid } = cache.readQuery({ query: appDataQuery });
      return client
        .query({
          query: projectQuery,
          variables: { fullPath: projectPath, iid: issueIid },
        })
        .then(({ data, errors }) => {
          if (errors) {
            createFlash(
              s__('DesignManagement|An error occurred while loading designs. Please try again.'),
            );
            throw new Error(errors);
          }
          const edge = data.project.issue.designs.designs.edges.find(
            ({ node }) => node.filename === id,
          );
          return edge.node;
        })
        .catch(() => {
          createFlash(
            s__('DesignManagement|An error occurred while loading designs. Please try again.'),
          );
        });
    },
  },
});

export default new VueApollo({
  defaultClient,
});
