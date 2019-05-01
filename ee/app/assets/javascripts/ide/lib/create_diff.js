import { commitActionForFile } from '~/ide/stores/utils';
import { commitActionTypes } from '~/ide/constants';
import createFileDiff from './create_file_diff';

const filesWithChanges = ({ stagedFiles = [], changedFiles = [] }) => {
  // We need changed files to overwrite staged, so put them at the end.
  const changes = stagedFiles.concat(changedFiles).reduce((acc, file) => {
    const key = file.path;
    const action = commitActionForFile(file);
    const prev = acc[key];

    // If a file was deleted, which was previously added, then we should do nothing.
    if (action === commitActionTypes.delete && prev && prev.action === commitActionTypes.create) {
      delete acc[key];
    } else {
      acc[key] = { action, file };
    }

    return acc;
  }, {});

  // We need to clean "move" actions, because we can only support 100% similarity moves at the moment.
  // This is because the previous file's content might not be loaded.
  Object.values(changes)
    .filter(change => change.action === commitActionTypes.move)
    .forEach(change => {
      const prev = changes[change.file.prevPath];

      if (!prev) {
        return;
      }

      if (change.file.content === prev.file.content) {
        // If content is the same, continue with the move but don't do the prevPath's delete.
        delete changes[change.file.prevPath];
      } else {
        // Otherwise, treat the move as a delete / create.
        Object.assign(change, { action: commitActionTypes.create });
      }
    });

  return Object.values(changes);
};

const createDiff = state => {
  const changes = filesWithChanges(state);

  const toDelete = changes.filter(x => x.action === commitActionTypes.delete).map(x => x.file.path);

  const patch = changes
    .filter(x => x.action !== commitActionTypes.delete)
    .map(({ file, action }) => createFileDiff(file, action))
    .join('');

  return {
    patch,
    toDelete,
  };
};

export default createDiff;
