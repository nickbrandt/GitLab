import '~/pages/projects/tree/show/index';
import { parseBoolean } from '~/lib/utils/common_utils';
import initPathLocks from 'ee/path_locks';

document.addEventListener('DOMContentLoaded', () => {
  const treeContent = document.querySelector('.js-tree-content');

  if (treeContent && parseBoolean(treeContent.dataset.pathLocksAvailable)) {
    initPathLocks(treeContent.dataset.pathLocksToggle, treeContent.dataset.pathLocksPath);
  }
});
