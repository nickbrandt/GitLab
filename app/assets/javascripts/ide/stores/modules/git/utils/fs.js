/* eslint-disable no-use-before-define */
/* eslint-disable no-param-reassign */
import { joinPaths } from '~/lib/utils/url_utility';
import { createGitObjectBlob, createGitObjectTree, hashGitObject } from './models';
import { FS_TYPE_BLOB, FS_ROOT_PATH } from '../../../../constants';

export function updateObjectsWithBlob(context, file) {
  const obj = createGitObjectBlob(file);
  const key = hashGitObject(obj);

  if (!context.objects[key]) {
    context.objects[key] = obj;
  }

  return key;
}

export function updateObjectsWithTree(context, tree) {
  const childrenWithKeys = tree.children.map(({ type, name }) => {
    const fullPath = joinPaths(tree.path, name);
    const key = updateObjectsWithPath(context, fullPath);

    return { type, name, key };
  });

  const obj = createGitObjectTree({ children: childrenWithKeys });
  const key = hashGitObject(obj);

  if (!context.objects[key]) {
    context.objects[key] = obj;
  }

  return key;
}

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

export const updateObjects = context => {
  const root = context.fs[FS_ROOT_PATH];

  return updateObjectsWithTree(context, root);
};
