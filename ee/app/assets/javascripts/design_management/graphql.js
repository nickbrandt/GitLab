import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import appDataQuery from './queries/appData.graphql';
import allDesigns from './queries/allDesigns.graphql';

Vue.use(VueApollo);

const defaultClient = createDefaultClient({
  Query: {
    design(ctx, { id }, { cache }) {
      const { projectPath, issueIid } = cache.readQuery({ query: appDataQuery });
      const result = cache.readQuery({
        query: allDesigns,
        variables: { fullPath: projectPath, iid: issueIid },
      });

      return {
        ...result.project.issue.designs.designs.edges.find(
          ({ node }) => parseInt(node.id, 10) === id,
        ).node,
        // TODO: Remove this once backend exposes raw images
        image: 'http://via.placeholder.com/1000',
      };
    },
  },
});

export default new VueApollo({
  defaultClient,
});
