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
 * @param {Object} objects
 */
export function updateObjectsWithBlob(objects, file) {
  const obj = createGitObjectBlob(file);
  const key = hashGitObject(obj);

  if (!objects[key]) {
    objects[key] = obj;
  }

  return key;
}

function updateObjectsWithTreeChildren(objects, children) {
  const obj = createGitObjectTree({ children });
  const key = hashGitObject(obj);

  if (!objects[key]) {
    objects[key] = obj;
  }

  return key;
}

/**
 *
 * @param {{rootRef: String, objects: Object, fs: Object, lastTimestamp: Number}} context
 */
export function updateObjectsWithTree(context, tree) {
  const childrenWithKeys = getChildrenWithKeys(context, tree);

  return updateObjectsWithTreeChildren(context.objects, childrenWithKeys);
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
    return updateObjectsWithBlob(context.objects, entry);
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

export const loadBlobContent = (objects, ref, path, content) => {
  const obj = objects[ref];

  if (!obj) {
    console.error('[ide.git.fs] Expected to find obj with ref', ref);
    return '';
  }

  if (!path) {
    return updateObjectsWithBlob(objects, { content, isLoaded: true });
  }

  const [curPath, ...nextParts] = path.split('/');
  const nextPath = nextParts.join('/');

  const newChildren = obj.data.children.map(child => {
    if (child.name !== curPath) {
      return child;
    }

    return {
      ...child,
      key: loadBlobContent(objects, child.key, nextPath, content),
    };
  });

  return updateObjectsWithTreeChildren(objects, newChildren);
};
