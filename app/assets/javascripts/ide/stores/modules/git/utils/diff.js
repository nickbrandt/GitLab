/* eslint-disable import/prefer-default-export */
import { getTreeChildSortKey } from '../../file_system/utils/models';

const getFullPath = (path, name) => {
  return path ? `${path}/${name}` : name;
};

const createAddedDiffEntry = path => {
  return {
    path,
    modification: 'added',
  };
};

const createModifiedDiffEntry = (path, headObjId) => {
  return {
    path,
    headObjId,
    modification: 'modified',
  };
};

const createRemovedDiffEntry = (path, headObjId) => {
  return {
    path,
    headObjId,
    modification: 'removed',
  };
};

const createAddedForAllBlobs = (objects, { type, name, key }, path = '') => {
  const fullPath = getFullPath(path, name);

  if (type === 'blob') {
    return [createAddedDiffEntry(fullPath)];
  }

  const childObj = objects[key];

  return childObj.data.children.flatMap(grandChild =>
    createAddedForAllBlobs(objects, grandChild, fullPath),
  );
};

const createRemovedForAllBlobs = (objects, { type, name, key }, path = '') => {
  const fullPath = getFullPath(path, name);

  if (type === 'blob') {
    return [createRemovedDiffEntry(fullPath, key)];
  }

  const childObj = objects[key];

  return childObj.data.children.flatMap(grandChild =>
    createRemovedForAllBlobs(objects, grandChild, fullPath),
  );
};

const calculateTreeDiff = (objects, atree, btree, path = '') => {
  const diff = [];
  const alen = atree.data.children.length;
  const blen = btree.data.children.length;

  let aidx = 0;
  let bidx = 0;

  while (aidx < alen || bidx < blen) {
    const achild = atree.data.children[aidx];
    const bchild = btree.data.children[bidx];

    // if we're all out of childrens in the atree so add the bchild
    if (!achild) {
      diff.push(...createAddedForAllBlobs(objects, bchild, path));

      // next b child
      bidx += 1;
    }
    // if we're all out of children in the btree, then we must have removed this from the atree
    else if (!bchild) {
      diff.push(...createRemovedForAllBlobs(objects, achild, path));

      // next a child
      aidx += 1;
    } else {
      const aSortKey = getTreeChildSortKey(achild);
      const bSortKey = getTreeChildSortKey(bchild);

      if (aSortKey === bSortKey && achild.key === bchild.key) {
        // next children :)
        aidx += 1;
        bidx += 1;
      } else if (aSortKey === bSortKey) {
        const fullPath = getFullPath(path, achild.name);
        // if this is a blob, then we must have modified it
        if (achild.type === 'blob') {
          diff.push(createModifiedDiffEntry(fullPath, achild.key));
        } else {
          diff.push(
            ...calculateTreeDiff(objects, objects[achild.key], objects[bchild.key], fullPath),
          );
        }

        aidx += 1;
        bidx += 1;
      } else if (aSortKey < bSortKey) {
        // we deleted a child from a, so we have to add that and catch up the idx
        diff.push(...createRemovedForAllBlobs(objects, achild, path));
        aidx += 1;
      } else {
        // we must have added a child in b, so we have to add it and catch up the idx
        diff.push(...createAddedForAllBlobs(objects, bchild, path));
        bidx += 1;
      }
    }
  }

  return diff;
};

export const calculateDiff = (objects, refA, refB) => {
  if (refA === refB) {
    return [];
  }

  const objA = objects[refA];
  const objB = objects[refB];

  return calculateTreeDiff(objects, objA, objB);
};
