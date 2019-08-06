import appDataQuery from '../graphql/queries/appData.query.graphql';
import getVersionDesignsQuery from '../graphql/queries/getVersionDesigns.query.graphql';
import projectQuery from '../graphql/queries/project.query.graphql';
import { extractNodes } from '../utils/design_management_utils';

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
      update: data => extractNodes(data.project.issue.designs.designs),
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
      update: data => extractNodes(data.project.issue.designs.designs),
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
