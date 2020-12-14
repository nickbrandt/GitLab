import { registerSchema } from '~/ide/utils';
import Api from '~/api';

// For CI config schemas the filename must match
// '*.gitlab-ci.yml' regardless of project configuration.
// https://gitlab.com/gitlab-org/gitlab/-/issues/293641
import { SCHEMA_FILE_NAME_MATCH } from './constants';

/**
 * Gets the URI of CI config JSON schema file
 */
const getCiSchemaUri = ({ projectPath, ref }) => {
  const [namespace, project] = projectPath.split('/');

  return Api.buildUrl(Api.projectFileSchemaPath)
    .replace(':namespace_path', namespace)
    .replace(':project_path', project)
    .replace(':ref', ref)
    .replace(':filename', SCHEMA_FILE_NAME_MATCH);
};

export default {
  /**
   * Registers a schema in a model based on project properties
   * and the name of the file that is edited.
   *
   * @param {Object} opts
   * @param {String} opts.projectPath - Namespace and project in the form `namespace/project`
   * @param {String?} opts.ref
   */
  registerCiSchema({ projectPath, ref = 'master' }) {
    // TODO Check syntax
    const fileName = this.getModel()
      .uri.path.split('/')
      .pop();
    registerSchema({
      uri: getCiSchemaUri({ projectPath, ref }),
      fileMatch: [fileName],
    });
  },
};
