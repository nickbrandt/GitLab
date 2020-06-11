/* eslint-disable import/prefer-default-export */
import { insertIntoTree } from './tree';
import { splitPath } from './path';

const TYPE_BLOB = 'blob';
const TYPE_TREE = 'tree';

const ROOT_PATH = '';

const createBaseFileObject = (type, { path = ROOT_PATH, name = ROOT_PATH }) => {
  return {
    type,
    timestamp: 0,
    path,
    name,
  };
};

const createBlob = (...args) => {
  return {
    ...createBaseFileObject(TYPE_BLOB, ...args),
    isLoaded: false,
    content: '',
    active: false,
  };
};

const createTree = (...args) => {
  return {
    ...createBaseFileObject(TYPE_TREE, ...args),
    children: [],
    opened: false,
  };
};

const insertEntry = (files, path, type, createFn) => {
  if (!path || files[path]) {
    return;
  }

  const [parentPath, name] = splitPath(path);

  Object.assign(files, {
    [path]: createFn({ path, name }),
  });

  insertEntry(files, parentPath, TYPE_TREE, createTree);

  insertIntoTree(files[parentPath], type, name);
};

export const parseToFileObjects = paths => {
  const files = {};

  const rootTree = createTree({});
  files[ROOT_PATH] = rootTree;

  paths.forEach(path => {
    insertEntry(files, path, TYPE_BLOB, createBlob);
  });

  return files;
};
