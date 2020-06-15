/* eslint-disable no-use-before-define */
/* eslint-disable no-param-reassign */
import { groupBy } from 'lodash';
import { joinPaths } from '~/lib/utils/url_utility';
import { createGitObjectBlob, createGitObjectTree, hashGitObject } from './models';
import { FS_TYPE_BLOB, FS_ROOT_PATH } from '../../../../constants';
import { getTreeChildSortKey } from '../../file_system/utils/models';

const getTreeChildKey = (context, tree, treeChild, prevChildren) => {
  const { lastTimestamp } = context;

  const sortKey = getTreeChildSortKey(treeChild);
  const prevChild = prevChildren[sortKey];

  if (prevChild && lastTimestamp >= treeChild.timestamp) {
    return prevChild.key;
  }

  const fullPath = joinPaths(tree.path, treeChild.name);
  return updateObjectsWithPath(context, fullPath);
};

const getChildrenWithKeys = (context, tree) => {
  const { objects, rootRef } = context;
  const prevObj = rootRef && objects[rootRef];
  const prevChildren = prevObj ? groupBy(prevObj.data.children, getTreeChildSortKey) : {};

  return tree.children.map(treeChild => {
    const { name, type } = treeChild;

    return {
      type,
      name,
      key: getTreeChildKey(context, tree, treeChild, prevChildren),
    };
  });
};

/**
 *
 * @param {{rootRef: String, objects: Object, fs: Object, lastTimestamp: Number}} context
 */
export function updateObjectsWithBlob(context, file) {
  const obj = createGitObjectBlob(file);
  const key = hashGitObject(obj);

  if (!context.objects[key]) {
    context.objects[key] = obj;
  }

  return key;
}

/**
 *
 * @param {{rootRef: String, objects: Object, fs: Object, lastTimestamp: Number}} context
 */
export function updateObjectsWithTree(context, tree) {
  const childrenWithKeys = getChildrenWithKeys(context, tree);

  const obj = createGitObjectTree({ children: childrenWithKeys });
  const key = hashGitObject(obj);

  if (!context.objects[key]) {
    context.objects[key] = obj;
  }

  return key;
}

/**
 *
 * @param {{rootRef: String, objects: Object, fs: Object, lastTimestamp: Number}} context
 */
export function updateObjectsWithPath(context, path) {
  const entry = context.fs[path];

  if (!entry) {
    console.error('[ide.git.fs] expected to find entry at', path);
    return '';
  }

  if (entry.type === FS_TYPE_BLOB) {
    return updateObjectsWithBlob(context, entry);
  }

  return updateObjectsWithTree(context, entry);
}

/**
 *
 * @param {{rootRef: String, objects: Object, fs: Object, lastTimestamp: Number}} context
 */
export const updateObjects = context => {
  const root = context.fs[FS_ROOT_PATH];

  return updateObjectsWithTree(context, root);
};
