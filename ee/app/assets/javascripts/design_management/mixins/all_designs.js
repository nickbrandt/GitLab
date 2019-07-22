import appDataQuery from '../queries/appData.graphql';
import getVersionDesignsQuery from '../queries/getVersionDesigns.query.graphql';
import projectQuery from '../queries/project.query.graphql';

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
      query: projectQuery,
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
    versionDesigns: {
      query: getVersionDesignsQuery,
      fetchPolicy: 'no-cache',
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.issueIid,
          atVersion: `gid://gitlab/DesignManagement::Version/${this.$route.query.version}`,
        };
      },
      skip() {
        this.$apollo.queries.versionDesigns.skip = !this.hasValidVersion();
      },
      update: data => data.project.issue.designs.designs.edges.map(({ node }) => node),
    },
  },
  data() {
    return {
      designs: [],
      error: false,
      projectPath: '',
      issueIid: null,
      versionDesigns: [],
    };
  },
  methods: {
    hasValidVersion() {
      if (Object.keys(this.$route.query).length === 0) {
        return false;
      }
      return this.allVersions.some(version => version.node.id.endsWith(this.$route.query.version));
    },
  },
};
