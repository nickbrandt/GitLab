import { registerSchema } from '~/ide/utils';
import Api from '~/api';

/**
 * Gets the URI of CI config JSON schema file
 */
const getCiSchemaUri = ({ projectPath, ref }) => {
  // Note: This `:filename` is hardcoded regardless
  // project configuration, see more:
  // - app/services/ide/schemas_config_service.rb
  const SCHEMA_FILE_NAME_MATCH = '.gitlab-ci.yml';
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
   * @param {String} opts.projectPath
   * @param {String} opts.ref
   * @param {String} opts.fileName - CI config file name, should match the "file-name" used in the editor.
   */
  registerCiSchema({ projectPath, ref = 'master', fileName = '.gitlab-ci.yml' }) {
    registerSchema({
      uri: getCiSchemaUri({ projectPath, ref }),
      fileMatch: [fileName],
    });
  },
};
