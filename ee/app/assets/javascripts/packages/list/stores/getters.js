import { LIST_KEY_PROJECT } from '../constants';
import { beautifyPath } from '../../shared/utils';

// eslint-disable-next-line import/prefer-default-export
export const getList = state =>
  state.packages.map(p => ({ ...p, projectPathName: beautifyPath(p[LIST_KEY_PROJECT]) }));
