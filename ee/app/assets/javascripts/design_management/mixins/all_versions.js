import projectQuery from '../graphql/queries/project.query.graphql';
import appDataQuery from '../graphql/queries/appData.query.graphql';
import { findVersionId } from '../utils/design_management_utils';

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
      update: data => data.project.issue.designCollection.versions.edges,
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
    isLatestVersion() {
      if (this.allVersions.length > 0) {
        const versionId = findVersionId(this.allVersions[0].node.id);
        return !this.$route.query.version || this.$route.query.version === versionId;
      }
      return true;
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
