/* eslint-disable import/prefer-default-export */
import { FS_TYPE_BLOB, FS_TYPE_TREE, FS_ROOT_PATH } from '../../../../constants';
import { insertIntoTree } from './tree';
import { splitPath } from './path';
import { createBlob, createTree } from './models';

const insertEntry = (files, path, type, createFn) => {
  if (!path || files[path]) {
    return;
  }

  const [parentPath, name] = splitPath(path);

  Object.assign(files, {
    [path]: createFn({ path, name }),
  });

  insertEntry(files, parentPath, FS_TYPE_TREE, createTree);

  insertIntoTree(files[parentPath], type, name);
};

export const parseToFileObjects = paths => {
  const files = {};

  const rootTree = createTree({});
  files[FS_ROOT_PATH] = rootTree;

  paths.forEach(path => {
    insertEntry(files, path, FS_TYPE_BLOB, createBlob);
  });

  return files;
};
