import { DEPENDENCY_LIST_TYPES } from './constants';

export default () => ({
  listTypes: [DEPENDENCY_LIST_TYPES.all],
  currentList: DEPENDENCY_LIST_TYPES.all.namespace,
});
