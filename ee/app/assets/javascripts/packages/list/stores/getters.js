import { LIST_KEY_PROJECT } from '../constants';
import { beautifyPath } from '../../shared/utils';

export const getList = state =>
  state.packages.map(p => ({ ...p, projectPathName: beautifyPath(p[LIST_KEY_PROJECT]) }));

export const getCommitLink = ({ config }) => ({ project_path: projectPath, pipeline = {} }) => {
  if (config.isGroupPage) {
    return `/${projectPath}/commit/${pipeline.sha}`;
  }

  return `../commit/${pipeline.sha}`;
};
