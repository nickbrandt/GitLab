import '~/pages/projects/tree/show/index';
import { parseBoolean } from '~/lib/utils/common_utils';
import initPathLocks from 'ee/path_locks';

document.addEventListener('DOMContentLoaded', () => {
  if (parseBoolean(document.querySelector('.js-tree-content').dataset.pathLocksAvailable)) {
    initPathLocks(
      document.querySelector('.js-tree-content').dataset.pathLocksToggle,
      document.querySelector('.js-tree-content').dataset.pathLocksPath,
    );
  }
});
