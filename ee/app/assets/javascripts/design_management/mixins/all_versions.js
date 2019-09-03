import projectQuery from '../graphql/queries/project.query.graphql';
import appDataQuery from '../graphql/queries/appData.query.graphql';

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
    allVersions: {
      query: projectQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.issueIid,
          atVersion: null,
        };
      },
      update: data => data.project.issue.designs.versions.edges,
    },
  },
  computed: {
    hasValidVersion() {
      return (
        this.$route.query.version &&
        this.allVersions &&
        this.allVersions.some(version => version.node.id.endsWith(this.$route.query.version))
      );
    },
    designsVersion() {
      return this.hasValidVersion
        ? `gid://gitlab/DesignManagement::Version/${this.$route.query.version}`
        : null;
    },
  },
  data() {
    return {
      allVersions: [],
      projectPath: '',
      issueIid: null,
    };
  },
};
