import createFlash from '~/flash';
import { s__ } from '~/locale';
import projectQuery from '../graphql/queries/project.query.graphql';
import { extractNodes } from '../utils/design_management_utils';
import allVersionsMixin from './all_versions';

export default {
  mixins: [allVersionsMixin],
  apollo: {
    designs: {
      query: projectQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.issueIid,
          atVersion: this.designsVersion,
        };
      },
      update: data => extractNodes(data.project.issue.designs.designs),
      error() {
        this.error = true;
      },
      result() {
        if (this.$route.query.version && !this.hasValidVersion) {
          createFlash(
            s__(
              'DesignManagement|Requested design version does not exist. Showing latest version instead',
            ),
          );
          this.$router.replace({ name: 'designs', query: { version: undefined } });
        }
      },
    },
  },
  data() {
    return {
      designs: [],
      error: false,
    };
  },
};
