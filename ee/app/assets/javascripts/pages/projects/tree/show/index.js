import '~/pages/projects/tree/show/index';
import initPathLocks from 'ee/path_locks';
import { parseBoolean } from '~/lib/utils/common_utils';

document.addEventListener('DOMContentLoaded', () => {
  const treeContent = document.querySelector('.js-tree-content');

  if (treeContent && parseBoolean(treeContent.dataset.pathLocksAvailable)) {
    initPathLocks(treeContent.dataset.pathLocksToggle, treeContent.dataset.pathLocksPath);
  }
});
