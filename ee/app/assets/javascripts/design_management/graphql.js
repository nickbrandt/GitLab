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

      return result.project.issue.designs.designs.edges.find(({ node }) => node.filename === id)
        .node;
    },
  },
});

export default new VueApollo({
  defaultClient,
});
