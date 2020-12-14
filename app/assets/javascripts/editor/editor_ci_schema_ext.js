import { registerSchema } from '~/ide/utils';
import Api from '~/api';

// For CI config schemas the filename must match
// '*.gitlab-ci.yml' regardless of project configuration.
// https://gitlab.com/gitlab-org/gitlab/-/issues/293641
import { SCHEMA_FILE_NAME_MATCH } from './constants';

const getCiSchemaUri = ({ projectNamespace, projectPath, ref }) =>
  Api.buildUrl(Api.projectFileSchemaPath)
    .replace(':namespace_path', projectNamespace)
    .replace(':project_path', projectPath)
    .replace(':ref', ref)
    .replace(':filename', SCHEMA_FILE_NAME_MATCH);

export default {
  /**
   * Registers a schema in a model based on project properties
   * and the name of the file that is currently edited.
   *
   * @param {Object} opts
   * @param {String} opts.projectNamespace
   * @param {String} opts.projectPath
   * @param {String?} opts.ref
   */
  registerCiSchema({ projectNamespace, projectPath, ref = 'master' } = {}) {
    const fileName = this.getModel()
      .uri.path.split('/')
      .pop();
    registerSchema({
      uri: getCiSchemaUri({ projectNamespace, projectPath, ref }),
      fileMatch: [fileName],
    });
  },
};
