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
  const prevKey = prevChild?.[0]?.key;
  const fullPath = joinPaths(tree.path, treeChild.name);

  if (prevKey && lastTimestamp >= context.fs[fullPath].timestamp) {
    return prevKey;
  }

  return updateObjectsWithPath(context, fullPath, prevKey);
};

const getChildrenWithKeys = (context, tree, baseRef) => {
  const { objects } = context;
  const prevObj = objects[baseRef];
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
export function updateObjectsWithTree(context, tree, baseRef) {
  const childrenWithKeys = getChildrenWithKeys(context, tree, baseRef);

  return updateObjectsWithTreeChildren(context.objects, childrenWithKeys);
}

/**
 *
 * @param {{rootRef: String, objects: Object, fs: Object, lastTimestamp: Number}} context
 */
export function updateObjectsWithPath(context, path, baseRef) {
  const entry = context.fs[path];

  if (!entry) {
    console.error('[ide.git.fs] expected to find entry at', path);
    return '';
  }

  if (entry.type === FS_TYPE_BLOB) {
    return updateObjectsWithBlob(context.objects, entry);
  }

  return updateObjectsWithTree(context, entry, baseRef);
}

/**
 *
 * @param {{rootRef: String, objects: Object, fs: Object, lastTimestamp: Number}} context
 */
export const updateObjects = context => {
  const root = context.fs[FS_ROOT_PATH];

  return updateObjectsWithTree(context, root, context.rootRef);
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
