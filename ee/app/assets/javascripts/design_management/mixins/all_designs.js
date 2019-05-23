import appDataQuery from '../queries/appData.graphql';
import allDesignsQuery from '../queries/allDesigns.graphql';

export default {
  apollo: {
    appData: {
      query: appDataQuery,
      manual: true,
      result({ data: { projectPath, issueIid } }) {
        this.projectPath = projectPath;
        this.issueIid = issueIid;
      },
    },
    designs: {
      query: allDesignsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.issueIid,
        };
      },
      update: data => data.project.issue.designs.designs.edges.map(({ node }) => node),
      error() {
        this.error = true;
      },
    },
  },
  data() {
    return {
      designs: [],
      error: false,
      projectPath: '',
      issueIid: null,
    };
  },
};
